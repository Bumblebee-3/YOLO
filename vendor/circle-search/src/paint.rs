use crate::geometry::Rect;
use gtk::{
    cairo::{Context, LinearGradient},
    gdk::prelude::GdkCairoContextExt,
    gdk_pixbuf::Pixbuf,
};
use std::f64::consts::PI;

pub fn rounded(c: &Context, r: Rect, radius: f64) {
    let a = radius.min(r.w / 2.).min(r.h / 2.);
    c.new_sub_path();
    c.arc(r.x + r.w - a, r.y + a, a, -PI / 2., 0.);
    c.arc(r.x + r.w - a, r.y + r.h - a, a, 0., PI / 2.);
    c.arc(r.x + a, r.y + r.h - a, a, PI / 2., PI);
    c.arc(r.x + a, r.y + a, a, PI, 1.5 * PI);
    c.close_path();
}

fn text(c: &Context, s: &str, x: f64, y: f64, size: f64, color: (f64, f64, f64)) {
    c.select_font_face(
        "sans-serif",
        gtk::cairo::FontSlant::Normal,
        gtk::cairo::FontWeight::Normal,
    );
    c.set_font_size(size);
    c.set_source_rgb(color.0, color.1, color.2);
    c.move_to(x, y);
    let _ = c.show_text(s);
}

pub fn background(c: &Context, image: Option<&Pixbuf>, w: f64, h: f64) {
    if let Some(image) = image {
        let _ = c.save();
        c.scale(w / f64::from(image.width()), h / f64::from(image.height()));
        c.set_source_pixbuf(image, 0., 0.);
        let _ = c.paint();
        let _ = c.restore();
    } else {
        let gradient = LinearGradient::new(0., 0., w, h);
        gradient.add_color_stop_rgb(0., 0.20, 0.26, 0.35);
        gradient.add_color_stop_rgb(1., 0.07, 0.10, 0.19);
        let _ = c.set_source(&gradient);
        let _ = c.paint();
        c.set_source_rgb(0.35, 0.38, 0.50);
        c.arc(w * 0.58, h * 0.50, h * 0.28, 0., 2. * PI);
        let _ = c.fill();
        c.set_source_rgb(0.73, 0.66, 0.57);
        rounded(
            c,
            Rect {
                x: w * 0.43,
                y: h * 0.28,
                w: w * 0.21,
                h: h * 0.45,
            },
            38.,
        );
        let _ = c.fill();
        text(
            c,
            "A little curiosity goes a long way.",
            52.,
            h - 58.,
            22.,
            (0.8, 0.8, 0.9),
        );
    }
}

pub fn chrome(c: &Context, w: f64, h: f64, save_only: bool) {
    // Keep the interior quiet: the light belongs at the screen perimeter.
    rounded(
        c,
        Rect {
            x: w - 76.,
            y: 24.,
            w: 52.,
            h: 52.,
        },
        26.,
    );
    c.set_source_rgba(0.025, 0.035, 0.05, 0.45);
    let _ = c.fill();
    c.set_source_rgba(0.94, 0.93, 1., 0.9);
    c.set_line_width(1.8);
    c.move_to(w - 56., 44.);
    c.line_to(w - 44., 56.);
    c.move_to(w - 44., 44.);
    c.line_to(w - 56., 56.);
    let _ = c.stroke();
    let bw = 450f64.min(w - 40.);
    let x = (w - bw) / 2.;
    rounded(
        c,
        Rect {
            x,
            y: h - 76.,
            w: bw,
            h: 48.,
        },
        24.,
    );
    c.set_source_rgba(0.025, 0.035, 0.05, 0.70);
    let _ = c.fill();
    text(
        c,
        if save_only {
            "Drag an area  ·  Release to save  ·  Esc to cancel"
        } else {
            "Drag an area  ·  Release to search  ·  Esc to cancel"
        },
        x + 23.,
        h - 47.,
        14.,
        (0.86, 0.88, 0.94),
    );
}

pub fn release_label(c: &Context, save_only: bool) {
    rounded(
        c,
        Rect {
            x: 0.,
            y: 0.,
            w: 184.,
            h: 40.,
        },
        20.,
    );
    c.set_source_rgba(0.035, 0.04, 0.065, 0.88);
    let _ = c.fill();
    text(
        c,
        if save_only {
            "Release to save"
        } else {
            "Release to search"
        },
        23.,
        26.,
        15.,
        (0.91, 0.87, 1.),
    );
}
