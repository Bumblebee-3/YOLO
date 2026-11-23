mod canvas;
mod effects;
mod geometry;
mod handoff;
mod paint;
mod profile;

use anyhow::{Context, Result, bail};
use geometry::Rect;
use gtk::{
    gdk,
    gdk_pixbuf::{Pixbuf, PixbufLoader},
    gio, glib,
    prelude::*,
};
use gtk4_layer_shell::{Edge, KeyboardMode, Layer, LayerShell};
use std::{cell::RefCell, path::PathBuf, process::Command, rc::Rc};

#[derive(Default)]
struct Options {
    save: Option<PathBuf>,
    monitor: Option<String>,
    lasso: bool,
    preview: Option<PathBuf>,
    diagnose: bool,
    reduced_motion: bool,
}

fn options() -> Result<Option<Options>> {
    let mut o = Options::default();
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--help" | "-h" => {
                println!(
                    "Circle Search — touch-friendly visual search for Wayland\n\nUsage: circle-search [OPTIONS]\n\n  --lasso                Circle an object; search its bounding rectangle\n  --monitor CONNECTOR    Select one display, e.g. eDP-1\n  --save PATH            Save the selection as PNG instead of searching\n  --render-preview PATH  Render a synthetic UI preview; no screen capture\n  --reduced-motion       Keep colours, disable continuous animation\n  --diagnose             Check desktop support without taking a screenshot\n  -V, --version          Show version and CPU target\n  -h, --help             Show this help\n\nDrag with a finger or mouse, release to search. Esc or × cancels.\nSearch sends only the selected crop to Google Lens in Firefox."
                );
                return Ok(None);
            }
            "--version" | "-V" => {
                println!(
                    "circle-search {} ({})",
                    env!("CARGO_PKG_VERSION"),
                    env!("CIRCLE_SEARCH_TARGET")
                );
                return Ok(None);
            }
            "--lasso" => o.lasso = true,
            "--reduced-motion" => o.reduced_motion = true,
            "--save" => o.save = Some(args.next().context("--save needs a path")?.into()),
            "--monitor" => o.monitor = Some(args.next().context("--monitor needs a connector")?),
            "--render-preview" => {
                o.preview = Some(args.next().context("--render-preview needs a path")?.into())
            }
            "--diagnose" => o.diagnose = true,
            _ => bail!("Unknown option {arg}. Try --help."),
        }
    }
    Ok(Some(o))
}

#[derive(Default)]
struct Selection {
    origin: Option<(f64, f64)>,
    rect: Option<Rect>,
    points: Vec<(f64, f64)>,
}

impl Selection {
    fn update(&mut self, dx: f64, dy: f64, width: f64, height: f64, lasso: bool) {
        if let Some(start) = self.origin {
            let p = (
                (start.0 + dx).clamp(0., width),
                (start.1 + dy).clamp(0., height),
            );
            if lasso {
                // Maintain exact bounds independently of the simplified visual trail.
                let previous = self
                    .rect
                    .unwrap_or(Rect::between(start, start, width, height));
                let lo = (previous.x.min(p.0), previous.y.min(p.1));
                let hi = (
                    (previous.x + previous.w).max(p.0),
                    (previous.y + previous.h).max(p.1),
                );
                self.rect = Some(Rect::between(lo, hi, width, height));
                if self.points.is_empty() {
                    self.points.push(start);
                }
                let last = self.points.last().unwrap();
                if (last.0 - p.0).hypot(last.1 - p.1) >= 2. {
                    if self.points.len() >= 1024 {
                        let mut i = 0;
                        self.points.retain(|_| {
                            let keep = i % 2 == 0;
                            i += 1;
                            keep
                        });
                    }
                    self.points.push(p);
                }
            } else {
                self.rect = Some(Rect::between(start, p, width, height));
            }
        }
    }
}

type SelectionResult = Rc<RefCell<Option<Pixbuf>>>;

fn capture(connector: &str) -> Result<Pixbuf> {
    let output = Command::new("grim")
        .args(["-o", connector, "-t", "ppm", "-"])
        .output()
        .context(
            "Could not run grim. Install the grim package using your distribution package manager",
        )?;
    if !output.status.success() {
        bail!(
            "grim failed for {connector}: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }
    let loader = PixbufLoader::new();
    loader.write(&output.stdout)?;
    loader.close()?;
    loader
        .pixbuf()
        .context("grim returned an invalid screenshot")
}

fn frozen_desktop(app: &gtk::Application, monitor: &gdk::Monitor, image: &Pixbuf) {
    // A separate Wayland surface is essential: changing the selection must not
    // invalidate, rescale or upload the desktop pixels on every frame.
    let window = gtk::ApplicationWindow::builder()
        .application(app)
        .title("Circle Search background")
        .decorated(false)
        .build();
    window.init_layer_shell();
    window.set_namespace(Some("circle-search-backdrop"));
    window.set_layer(Layer::Top);
    window.set_monitor(Some(monitor));
    window.set_keyboard_mode(KeyboardMode::None);
    window.set_exclusive_zone(-1);
    for edge in [Edge::Top, Edge::Bottom, Edge::Left, Edge::Right] {
        window.set_anchor(edge, true);
    }
    let picture = gtk::Picture::for_paintable(&gdk::Texture::for_pixbuf(image));
    picture.set_can_shrink(true);
    picture.set_content_fit(gtk::ContentFit::Fill);
    window.set_child(Some(&picture));
    window.present();
}

fn overlay(
    app: &gtk::Application,
    monitor: &gdk::Monitor,
    image: Pixbuf,
    opts: &Options,
    result: SelectionResult,
) {
    let window = gtk::ApplicationWindow::builder()
        .application(app)
        .title("Circle Search")
        .decorated(false)
        .build();
    window.add_css_class("circle-search-overlay");
    window.init_layer_shell();
    window.set_namespace(Some("circle-search"));
    window.set_layer(Layer::Overlay);
    window.set_monitor(Some(monitor));
    window.set_keyboard_mode(KeyboardMode::Exclusive);
    window.set_exclusive_zone(-1);
    for edge in [Edge::Top, Edge::Bottom, Edge::Left, Edge::Right] {
        window.set_anchor(edge, true);
    }
    let state = Rc::new(RefCell::new(Selection::default()));
    let area = canvas::Canvas::new(state.clone(), opts.save.is_some(), opts.reduced_motion);
    area.set_cursor_from_name(Some("crosshair"));
    area.set_focusable(true);
    window.set_child(Some(&area));

    let drag = gtk::GestureDrag::new();
    drag.set_button(1);
    let begin_state = state.clone();
    let weak_area = area.downgrade();
    let weak_app = app.downgrade();
    drag.connect_drag_begin(move |gesture, x, y| {
        let (Some(area), Some(app)) = (weak_area.upgrade(), weak_app.upgrade()) else {
            return;
        };
        if x >= f64::from(area.width()) - 84. && (16. ..84.).contains(&y) {
            app.quit();
            return;
        }
        *begin_state.borrow_mut() = Selection {
            origin: Some((x, y)),
            rect: None,
            points: vec![],
        };
        gesture.set_state(gtk::EventSequenceState::Claimed);
        area.queue_draw();
    });
    let update_state = state.clone();
    let weak_area = area.downgrade();
    let lasso = opts.lasso;
    drag.connect_drag_update(move |_, dx, dy| {
        if let Some(area) = weak_area.upgrade() {
            update_state.borrow_mut().update(
                dx,
                dy,
                area.width().into(),
                area.height().into(),
                lasso,
            );
            area.queue_draw();
        }
    });
    let end_state = state.clone();
    let weak_area = area.downgrade();
    let weak_app = app.downgrade();
    drag.connect_drag_end(move |_, dx, dy| {
        let (Some(area), Some(app)) = (weak_area.upgrade(), weak_app.upgrade()) else {
            return;
        };
        let mut s = end_state.borrow_mut();
        s.update(dx, dy, area.width().into(), area.height().into(), lasso);
        if let Some(rect) = s.rect.filter(|r| r.w >= 8. && r.h >= 8.) {
            if result.borrow().is_some() {
                return;
            }
            let (x, y, w, h) = rect.pixels(
                (area.width().into(), area.height().into()),
                (image.width(), image.height()),
            );
            *result.borrow_mut() = Some(image.new_subpixbuf(x, y, w, h));
            app.quit();
        } else {
            *s = Selection::default();
            area.queue_draw();
        }
    });
    let cancel_state = state.clone();
    let weak_area = area.downgrade();
    drag.connect_cancel(move |_, _| {
        *cancel_state.borrow_mut() = Selection::default();
        if let Some(area) = weak_area.upgrade() {
            area.queue_draw();
        }
    });
    area.add_controller(drag);
    let keys = gtk::EventControllerKey::new();
    let weak_app = app.downgrade();
    keys.connect_key_pressed(move |_, key, _, _| {
        if key == gdk::Key::Escape {
            if let Some(app) = weak_app.upgrade() {
                app.quit();
            }
            glib::Propagation::Stop
        } else {
            glib::Propagation::Proceed
        }
    });
    window.add_controller(keys);
    window.present();
    area.grab_focus();
    profile::attach(&area, state);
}

fn run() -> Result<()> {
    let Some(opts) = options()? else {
        return Ok(());
    };
    if let Some(path) = &opts.preview {
        canvas::preview(path)?;
        println!("Preview saved to {}", path.display());
        return Ok(());
    }
    if opts.save.as_ref().is_some_and(|path| path.exists()) {
        bail!("The --save file already exists. Choose a new file name.");
    }
    gtk::init().context(
        "Cannot connect to your desktop. Run this in a terminal inside your Wayland session",
    )?;
    if !gtk4_layer_shell::is_supported() {
        bail!(
            "This desktop does not support Wayland layer-shell. Use Hyprland, Sway, or another layer-shell compositor."
        );
    }
    let display = gdk::Display::default().context("No display available")?;
    let css = gtk::CssProvider::new();
    css.load_from_string("window.circle-search-overlay { background: transparent; background-image: none; box-shadow: none; }");
    gtk::style_context_add_provider_for_display(
        &display,
        &css,
        // The user's GTK stylesheet sets a background on every window. Override
        // it only for our overlay class so the selection surface stays alpha.
        gtk::STYLE_PROVIDER_PRIORITY_USER + 1,
    );
    let monitors = display.monitors();
    let mut screens = Vec::new();
    let mut matched = 0;
    for i in 0..monitors.n_items() {
        let monitor = monitors
            .item(i)
            .and_downcast::<gdk::Monitor>()
            .context("Invalid monitor")?;
        let connector = monitor
            .connector()
            .context("Display has no output connector name")?;
        if opts
            .monitor
            .as_ref()
            .is_some_and(|name| name != connector.as_str())
        {
            continue;
        }
        matched += 1;
        if opts.diagnose {
            println!(
                "Display {connector}: {} × {} logical pixels",
                monitor.geometry().width(),
                monitor.geometry().height()
            );
        } else {
            let image = capture(&connector)?;
            screens.push((monitor, image));
        }
    }
    if opts.diagnose {
        if matched == 0 {
            bail!("No matching displays. Check the --monitor connector name.");
        }
        for program in ["grim", "firefox"] {
            let status = Command::new(program)
                .arg(if program == "grim" { "-h" } else { "--version" })
                .output()
                .with_context(|| format!("Missing {program}"))?;
            if !status.status.success() {
                bail!("{program} --version failed");
            }
            println!("{program}: installed");
        }
        println!("Wayland layer-shell: supported");
        return Ok(());
    }
    if screens.is_empty() {
        bail!("No matching displays. Check --monitor or run --diagnose.");
    }
    let result: SelectionResult = Rc::new(RefCell::new(None));
    let selected = result.clone();
    let opts = Rc::new(opts);
    let ui_opts = opts.clone();
    let app = gtk::Application::builder()
        .application_id("dev.circle.Search")
        .flags(gio::ApplicationFlags::NON_UNIQUE)
        .build();
    app.connect_activate(move |app| {
        for (monitor, image) in &screens {
            frozen_desktop(app, monitor, image);
            overlay(app, monitor, image.clone(), &ui_opts, selected.clone());
        }
    });
    app.run_with_args::<&str>(&[]);
    for window in app.windows() {
        window.destroy();
    }
    display.sync();
    if let Some(selection) = result.borrow_mut().take() {
        let dimensions = (selection.width(), selection.height());
        let png = selection.save_to_bufferv("png", &[("compression", "2")])?;
        if let Some(path) = &opts.save {
            // Do not silently overwrite an existing image.
            use std::io::Write;
            use std::os::unix::fs::OpenOptionsExt;
            let mut file = std::fs::OpenOptions::new()
                .write(true)
                .create_new(true)
                .mode(0o600)
                .open(path)
                .with_context(|| {
                    format!("Cannot create {} (choose a new file name)", path.display())
                })?;
            file.write_all(&png)?;
            println!(
                "Saved {} × {} image to {}",
                dimensions.0,
                dimensions.1,
                path.display()
            );
        } else {
            handoff::open(&png, dimensions)?;
        }
    } else {
        println!("Cancelled.");
    }
    Ok(())
}

fn main() {
    // Set before GTK or any application thread starts. Prefer GPU rendering
    // when a render node is accessible, and avoid slow software GL otherwise.
    // An explicit user override is still respected.
    if std::env::var_os("GSK_RENDERER").is_none() {
        let gpu_available = std::fs::read_dir("/dev/dri").is_ok_and(|entries| {
            entries.flatten().any(|entry| {
                entry.file_name().to_string_lossy().starts_with("renderD")
                    && std::fs::OpenOptions::new()
                        .read(true)
                        .write(true)
                        .open(entry.path())
                        .is_ok()
            })
        });
        unsafe {
            std::env::set_var("GSK_RENDERER", if gpu_available { "gl" } else { "cairo" });
        }
    }
    if let Err(error) = run() {
        eprintln!("circle-search: {error:#}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod selection_tests {
    use super::*;

    #[test]
    fn long_lasso_keeps_early_extremes_after_trail_simplification() {
        let mut selection = Selection {
            origin: Some((100., 100.)),
            ..Selection::default()
        };
        selection.update(-100., -100., 1000., 1000., true);
        selection.update(900., 900., 1000., 1000., true);
        for i in 0..10_000 {
            selection.update(f64::from(i % 200), f64::from(i % 300), 1000., 1000., true);
        }
        selection.update(0., 0., 1000., 1000., true);
        assert_eq!(
            selection.rect,
            Some(Rect {
                x: 0.,
                y: 0.,
                w: 1000.,
                h: 1000.
            })
        );
        assert!(selection.points.len() <= 1024);
    }
}
