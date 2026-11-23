//! Aurora light is sampled into four narrow edge strips. The desktop and the
//! transparent center are never repainted into an animation texture.
use gtk::{gdk, glib, graphene, prelude::*};
use std::f32::consts::TAU;

const PHASES: usize = 512;

#[derive(Clone, Copy)]
struct Sample {
    distance: f32,
    core: f32,
    phase: usize,
}

struct Strip {
    bounds: graphene::Rect,
    width: i32,
    height: i32,
    samples: Vec<Sample>,
    texture: Option<gdk::MemoryTexture>,
}

#[derive(Clone, Copy, Default)]
struct Light {
    breadth: f32,
    strength: f32,
    color: [f32; 3],
}

pub struct Aurora {
    strips: Vec<Strip>,
    last_time: Option<f32>,
}

fn palette(phase: f32) -> [f32; 3] {
    let colors = [
        [1.0, 0.75, 0.70],
        [0.68, 0.97, 0.84],
        [0.30, 0.82, 1.0],
        [0.37, 0.64, 1.0],
        [0.65, 0.40, 1.0],
        [0.84, 0.46, 1.0],
        [1.0, 0.52, 0.87],
        [1.0, 0.66, 0.76],
    ];
    let p = phase.rem_euclid(1.) * colors.len() as f32;
    let i = p.floor() as usize;
    let f = p.fract();
    let a = colors[i];
    let b = colors[(i + 1) % colors.len()];
    std::array::from_fn(|n| a[n] + (b[n] - a[n]) * f)
}

impl Aurora {
    pub fn new(width: i32, height: i32) -> Self {
        let (w, h) = (width as f32, height as f32);
        let band = 64f32.min(w / 3.).min(h / 3.);
        let bounds = [
            graphene::Rect::new(0., 0., w, band),
            graphene::Rect::new(0., h - band, w, band),
            graphene::Rect::new(0., band, band, h - 2. * band),
            graphene::Rect::new(w - band, band, band, h - 2. * band),
        ];
        let strips = bounds
            .into_iter()
            .enumerate()
            .map(|(i, bounds)| {
                // Full resolution across the glow's thickness; lower resolution
                // along the edge, where its colours and waves change gradually.
                let nx = (bounds.width() / if i < 2 { 3. } else { 1. }).ceil() as i32;
                let ny = (bounds.height() / if i < 2 { 1. } else { 3. }).ceil() as i32;
                let mut samples = Vec::with_capacity((nx * ny) as usize);
                let radius = 22f32.min(w / 4.).min(h / 4.);
                for y in 0..ny {
                    for x in 0..nx {
                        let px =
                            bounds.x() + (x as f32 + 0.5) * bounds.width() / nx as f32 - w / 2.;
                        let py =
                            bounds.y() + (y as f32 + 0.5) * bounds.height() / ny as f32 - h / 2.;
                        let qx = px.abs() - (w / 2. - 8.) + radius;
                        let qy = py.abs() - (h / 2. - 8.) + radius;
                        let distance =
                            (qx.max(0.).hypot(qy.max(0.)) + qx.max(qy).min(0.) - radius).abs();
                        let phase = ((py / h).atan2(px / w) / TAU).rem_euclid(1.);
                        samples.push(Sample {
                            distance,
                            core: (-(distance / 1.5).powi(2)).exp() * 0.62,
                            phase: ((phase * PHASES as f32) as usize).min(PHASES - 1),
                        });
                    }
                }
                Strip {
                    bounds,
                    width: nx,
                    height: ny,
                    samples,
                    texture: None,
                }
            })
            .collect();
        Self {
            strips,
            last_time: None,
        }
    }

    pub fn draw(&mut self, snapshot: &gtk::Snapshot, t: f32, opacity: f32) {
        if self.last_time != Some(t) {
            let swell = 0.18 + 0.82 * (0.5 + 0.5 * (t * 1.28).sin()).powf(1.3);
            let lights: [Light; PHASES] = std::array::from_fn(|i| {
                let p = i as f32 / PHASES as f32;
                let wave = 0.5 + 0.5 * (p * TAU * 3. - t * 2.1).sin();
                let wave2 = 0.5 + 0.5 * (p * TAU * 3. + t * 1.45).sin();
                Light {
                    breadth: 7. + swell * (13. + 22. * wave),
                    strength: 0.25 + swell * (0.30 + 0.18 * wave2),
                    color: palette(p - t * 0.018),
                }
            });
            for strip in &mut self.strips {
                let mut pixels = Vec::with_capacity(strip.samples.len() * 4);
                for sample in &strip.samples {
                    let light = lights[sample.phase];
                    let d = (sample.distance / light.breadth).clamp(0., 1.);
                    let soft = 1. - d * d * (3. - 2. * d);
                    let alpha = (soft * soft * light.strength + sample.core).min(0.96);
                    // A pearly centre, with richer violet/cyan in the soft halo.
                    let white = sample.core * 0.42;
                    for color in light.color {
                        pixels.push(((color + (1. - color) * white) * alpha * 255.).round() as u8);
                    }
                    pixels.push((alpha * 255.).round() as u8);
                }
                let bytes = glib::Bytes::from_owned(pixels);
                strip.texture = Some(gdk::MemoryTexture::new(
                    strip.width,
                    strip.height,
                    gdk::MemoryFormat::R8g8b8a8Premultiplied,
                    &bytes,
                    strip.width as usize * 4,
                ));
            }
            self.last_time = Some(t);
        }
        snapshot.push_opacity(opacity.into());
        for strip in &self.strips {
            if let Some(texture) = &strip.texture {
                snapshot.append_texture(texture, &strip.bounds);
            }
        }
        snapshot.pop();
    }
}
