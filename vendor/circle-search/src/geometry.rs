#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Rect {
    pub x: f64,
    pub y: f64,
    pub w: f64,
    pub h: f64,
}

impl Rect {
    pub fn between(a: (f64, f64), b: (f64, f64), width: f64, height: f64) -> Self {
        let (ax, ay) = (a.0.clamp(0., width), a.1.clamp(0., height));
        let (bx, by) = (b.0.clamp(0., width), b.1.clamp(0., height));
        Self {
            x: ax.min(bx),
            y: ay.min(by),
            w: (ax - bx).abs(),
            h: (ay - by).abs(),
        }
    }

    pub fn pixels(self, view: (f64, f64), image: (i32, i32)) -> (i32, i32, i32, i32) {
        let sx = f64::from(image.0) / view.0;
        let sy = f64::from(image.1) / view.1;
        let x = (self.x * sx).floor().clamp(0., f64::from(image.0 - 1)) as i32;
        let y = (self.y * sy).floor().clamp(0., f64::from(image.1 - 1)) as i32;
        let right = ((self.x + self.w) * sx)
            .ceil()
            .clamp(f64::from(x + 1), f64::from(image.0)) as i32;
        let bottom = ((self.y + self.h) * sy)
            .ceil()
            .clamp(f64::from(y + 1), f64::from(image.1)) as i32;
        (x, y, right - x, bottom - y)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn reverse_drag_and_out_of_bounds() {
        assert_eq!(
            Rect::between((120., 90.), (-10., 20.), 100., 80.),
            Rect {
                x: 0.,
                y: 20.,
                w: 100.,
                h: 60.
            }
        );
    }
    #[test]
    fn fractional_scale_covers_entire_selection() {
        let r = Rect {
            x: 10.2,
            y: 4.3,
            w: 20.1,
            h: 10.2,
        };
        assert_eq!(r.pixels((100., 80.), (150, 120)), (15, 6, 31, 16));
    }
    #[test]
    fn last_pixel_stays_in_bounds() {
        let r = Rect::between((99.5, 79.5), (200., 200.), 100., 80.);
        assert_eq!(r.pixels((100., 80.), (150, 120)), (149, 119, 1, 1));
    }
}
