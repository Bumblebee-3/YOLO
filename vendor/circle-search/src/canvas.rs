//! Transparent overlay: the compositor draws the desktop, not this app.
use crate::{Selection, effects, paint};
use gtk::{gdk, glib, graphene, gsk, prelude::*, subclass::prelude::*};
use std::{
    cell::{Cell, RefCell},
    rc::Rc,
};

mod imp {
    use super::*;

    #[derive(Default)]
    pub struct Canvas {
        pub(super) scene: RefCell<Option<Scene>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for Canvas {
        const NAME: &'static str = "CircleSearchCanvas";
        type Type = super::Canvas;
        type ParentType = gtk::Widget;
    }
    impl ObjectImpl for Canvas {}
    impl WidgetImpl for Canvas {
        fn snapshot(&self, snapshot: &gtk::Snapshot) {
            let widget = self.obj();
            if let Some(scene) = self.scene.borrow_mut().as_mut() {
                scene.draw(snapshot, widget.width(), widget.height());
            }
        }
    }
}

glib::wrapper! {
    pub struct Canvas(ObjectSubclass<imp::Canvas>)
        @extends gtk::Widget,
        @implements gtk::Accessible, gtk::Buildable, gtk::ConstraintTarget;
}

impl Canvas {
    pub(crate) fn new(
        state: Rc<RefCell<Selection>>,
        save_only: bool,
        reduced_motion: bool,
    ) -> Self {
        let canvas: Self = glib::Object::new();
        *canvas.imp().scene.borrow_mut() = Some(Scene {
            state,
            save_only,
            cache: None,
            time: 1.,
            hover_close: false,
        });
        if !reduced_motion {
            let start = Cell::new(None::<i64>);
            let last = Cell::new(0i64);
            let cadence = if std::env::var("GSK_RENDERER").as_deref() == Ok("cairo") {
                33_000
            } else {
                16_000
            };
            canvas.add_tick_callback(move |canvas, clock| {
                let now = clock.frame_time();
                let origin = start.get().unwrap_or(now);
                start.set(Some(origin));
                if now - last.get() >= cadence {
                    if let Some(scene) = canvas.imp().scene.borrow_mut().as_mut() {
                        scene.time = (now - origin) as f32 / 1_000_000.;
                    }
                    last.set(now);
                    canvas.queue_draw();
                }
                glib::ControlFlow::Continue
            });
        }
        let motion = gtk::EventControllerMotion::new();
        let weak = canvas.downgrade();
        motion.connect_motion(move |_, x, y| {
            if let Some(canvas) = weak.upgrade()
                && let Some(scene) = canvas.imp().scene.borrow_mut().as_mut()
            {
                let hover = x >= f64::from(canvas.width()) - 84. && (16. ..84.).contains(&y);
                if hover != scene.hover_close {
                    scene.hover_close = hover;
                    canvas.queue_draw();
                }
            }
        });
        let weak = canvas.downgrade();
        motion.connect_leave(move |_| {
            if let Some(canvas) = weak.upgrade() {
                if let Some(scene) = canvas.imp().scene.borrow_mut().as_mut() {
                    scene.hover_close = false;
                }
                canvas.queue_draw();
            }
        });
        canvas.add_controller(motion);
        canvas.set_hexpand(true);
        canvas.set_vexpand(true);
        canvas
    }
}

struct Cache {
    width: i32,
    height: i32,
    glow: effects::Aurora,
    close: gsk::RenderNode,
    footer: gsk::RenderNode,
    label: gsk::RenderNode,
}

struct Scene {
    state: Rc<RefCell<Selection>>,
    save_only: bool,
    cache: Option<Cache>,
    time: f32,
    hover_close: bool,
}

impl Scene {
    fn draw(&mut self, snapshot: &gtk::Snapshot, width: i32, height: i32) {
        if width <= 0 || height <= 0 {
            return;
        }
        let bounds = graphene::Rect::new(0., 0., width as f32, height as f32);
        if self
            .cache
            .as_ref()
            .is_none_or(|c| c.width != width || c.height != height)
        {
            let record = |rect: graphene::Rect| {
                let node = gtk::Snapshot::new();
                let c = node.append_cairo(&rect);
                paint::chrome(&c, width.into(), height.into(), self.save_only);
                drop(c);
                node.to_node().unwrap()
            };

            let close = record(graphene::Rect::new(width as f32 - 82., 20., 62., 62.));
            let footer = record(graphene::Rect::new(
                0.,
                height as f32 - 102.,
                width as f32,
                82.,
            ));
            let label = gtk::Snapshot::new();
            let c = label.append_cairo(&graphene::Rect::new(0., 0., 184., 40.));
            paint::release_label(&c, self.save_only);
            drop(c);
            self.cache = Some(Cache {
                width,
                height,
                glow: effects::Aurora::new(width, height),
                close,
                footer,
                label: label.to_node().unwrap(),
            });
        }
        let cache = self.cache.as_mut().unwrap();
        let state = self.state.borrow();
        let t = self.time;
        let enter = 1. - (1. - (t / 0.45).clamp(0., 1.)).powi(3);
        let dim = gdk::RGBA::new(0.015, 0.025, 0.035, 0.24 * enter);
        if let Some(r) = state.rect.filter(|r| r.w > 1. && r.h > 1.) {
            let rect = graphene::Rect::new(r.x as f32, r.y as f32, r.w as f32, r.h as f32);
            let rounded =
                gsk::RoundedRect::from_rect(rect, 16f32.min(r.w as f32 / 2.).min(r.h as f32 / 2.));
            let mask = gsk::PathBuilder::new();
            mask.add_rect(&bounds);
            mask.add_rounded_rect(&rounded);
            snapshot.append_fill(&mask.to_path(), gsk::FillRule::EvenOdd, &dim);
            snapshot.append_border(
                &rounded,
                &[2.; 4],
                &[
                    gdk::RGBA::new(0.83, 0.68, 1., 0.95),
                    gdk::RGBA::new(1., 0.79, 0.84, 0.95),
                    gdk::RGBA::new(0.55, 0.91, 0.96, 0.95),
                    gdk::RGBA::new(0.67, 0.74, 1., 0.95),
                ],
            );
            if state.points.len() > 1 {
                let path = gsk::PathBuilder::new();
                path.move_to(state.points[0].0 as f32, state.points[0].1 as f32);
                for p in &state.points[1..] {
                    path.line_to(p.0 as f32, p.1 as f32);
                }
                let stroke = gsk::Stroke::new(2.);
                stroke.set_line_cap(gsk::LineCap::Round);
                stroke.set_line_join(gsk::LineJoin::Round);
                snapshot.append_stroke(
                    &path.to_path(),
                    &stroke,
                    &gdk::RGBA::new(0.85, 0.80, 1., 0.94),
                );
            }
            let x = (r.x + r.w / 2. - 92.).clamp(12., (f64::from(width) - 196.).max(12.));
            let y = (r.y + r.h + 16.).min(f64::from(height) - 154.).max(105.);
            snapshot.save();
            snapshot.translate(&graphene::Point::new(x as f32, y as f32));
            snapshot.append_node(&cache.label);
            snapshot.restore();
        } else {
            snapshot.append_color(&dim, &bounds);
        }
        cache.glow.draw(snapshot, t, enter);
        snapshot.push_opacity(enter.into());
        snapshot.append_node(&cache.close);
        if self.hover_close {
            snapshot.append_border(
                &gsk::RoundedRect::from_rect(
                    graphene::Rect::new(width as f32 - 76., 24., 52., 52.),
                    26.,
                ),
                &[1.; 4],
                &[gdk::RGBA::new(0.85, 0.78, 1., 0.8); 4],
            );
        }
        snapshot.save();
        snapshot.translate(&graphene::Point::new(0., 12. * (1. - enter)));
        snapshot.append_node(&cache.footer);
        snapshot.restore();
        snapshot.pop();
    }
}

/// Render the actual scene with synthetic content; never captures the desktop.
pub(crate) fn preview(path: &std::path::Path) -> anyhow::Result<()> {
    gtk::init()?;
    let snapshot = gtk::Snapshot::new();
    let bounds = graphene::Rect::new(0., 0., 1440., 900.);
    let c = snapshot.append_cairo(&bounds);
    paint::background(&c, None, 1440., 900.);
    drop(c);
    let time = std::env::var("CIRCLE_SEARCH_PREVIEW_TIME")
        .ok()
        .and_then(|s| s.parse::<f32>().ok())
        .filter(|t| t.is_finite())
        .unwrap_or(1.8);
    let state = Rc::new(RefCell::new(Selection {
        origin: Some((580., 220.)),
        rect: Some(crate::geometry::Rect {
            x: 580.,
            y: 220.,
            w: 380.,
            h: 460.,
        }),
        points: vec![],
    }));
    Scene {
        state,
        save_only: false,
        cache: None,
        time,
        hover_close: false,
    }
    .draw(&snapshot, 1440, 900);
    let node = snapshot.to_node().unwrap();
    let renderer = gsk::CairoRenderer::new();
    renderer.realize(None)?;
    let texture = renderer.render_texture(&node, Some(&bounds));
    let result = texture.save_to_png(path);
    renderer.unrealize();
    result?;
    Ok(())
}
