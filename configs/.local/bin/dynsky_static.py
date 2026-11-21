"""Time-of-day renderer for the static gas-station wallpaper (full 24-bit colour, no GIF limits)."""
import math
import numpy as np, cv2
from dynsky import smoothstep, sun_state, sun_events, moon_phase, make_stars  # shared astronomy + stars

W, H = 2880, 1861            # working / output size (source is 4680x3024)
HOR = 960                    # y of the mountain ridge line used for the sun/moon arcs
E_NATIVE = 34                # sun elevation the original painting corresponds to (golden afternoon)

# sky colours by sun elevation: (elev, zenith RGB, horizon RGB)
STOPS = [
    (-18, (  3,   6,  18), ( 10,  18,  44)),
    (-12, (  8,  14,  42), ( 36,  52,  98)),
    ( -7, ( 20,  34,  88), (122,  90, 132)),
    ( -2, ( 40,  66, 128), (255, 128,  86)),
    (  3, ( 52,  88, 160), (255, 184, 120)),
    (  9, ( 40,  84, 160), (170, 196, 230)),
    ( 25, ( 24,  58, 140), ( 70, 118, 196)),
    ( 60, ( 20,  52, 128), ( 44,  90, 168)),
]
# cloud lit colour by sun elevation (the shaded parts get an ambient blend of the sky)
CLOUD_LIT = [
    (-18, ( 70,  86, 130)), (-10, (110, 120, 160)), (-5, (200, 120, 130)), (-1, (255, 135, 100)),
    (  4, (255, 175, 105)), ( 12, (255, 222, 170)), (30, (255, 232, 190)), (60, (255, 246, 232)),
]
# foreground grade by elevation: (elev, gain, tint RGB, saturation)
GRADE = [
    (-18, 0.16, (0.50, 0.68, 1.18), 0.55), (-10, 0.30, (0.62, 0.72, 1.05), 0.70), (-4, 0.55, (1.00, 0.76, 0.84), 0.90),
    (  2, 0.78, (1.30, 0.92, 0.68), 1.05), ( 10, 0.92, (1.10, 1.00, 0.88), 1.02), (34, 1.00, (1.00, 1.00, 1.00), 1.00),
    ( 60, 1.04, (0.97, 1.00, 1.04), 0.98),
]

def _interp(table, e):
    es = [t[0] for t in table]
    e = max(es[0], min(es[-1], e))
    for a, b in zip(table, table[1:]):
        if a[0] <= e <= b[0]:
            t = (e - a[0]) / (b[0] - a[0])
            return [np.array(x, dtype=np.float64) * (1 - t) + np.array(y, dtype=np.float64) * t for x, y in zip(a[1:], b[1:])]

def build_masks(im_bgr):
    b, g, r = [im_bgr[..., i].astype(np.float32) for i in range(3)]
    L = cv2.cvtColor(im_bgr, cv2.COLOR_BGR2GRAY).astype(np.float32)
    Lb = cv2.GaussianBlur(L, (0, 0), 1.2)
    mean = cv2.blur(Lb, (11, 11)); tex = np.sqrt(np.clip(cv2.blur(Lb * Lb, (11, 11)) - mean * mean, 0, None))
    cloud = (r > 100) & (g > 110) & (b > 130)
    blue = (tex < 2.2) & ((b - r) > 70) & (b > 110)
    cand = (cloud | blue).astype(np.uint8) * 255
    cand = cv2.morphologyEx(cand, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    cand = cv2.morphologyEx(cand, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (19, 19)))
    n, lbl = cv2.connectedComponents(cand)
    keep = np.zeros_like(cand)
    for k in range(1, n):
        c = lbl == k
        if c[:3, :].any() and c.sum() > 20000:
            keep[c] = 255
    inv = (keep == 0).astype(np.uint8)
    n2, lbl2, stats, _ = cv2.connectedComponentsWithStats(inv, connectivity=4)
    for k in range(1, n2):
        x, y, w_, h_, area = stats[k]
        if area < 40000 and (y + h_) < H - 2:
            keep[lbl2 == k] = 255
    keep = cv2.erode(keep, np.ones((3, 3), np.uint8))
    sky = cv2.GaussianBlur(keep, (0, 0), 1.3).astype(np.float32) / 255
    # cloud alpha inside the sky: clouds are bright (high R), clear sky is not
    calpha = smoothstep(45, 140, r) * sky
    # cloud shading 0..1 from the painting's own light/shadow structure
    cl = calpha > 0.6
    lo, hi = np.percentile(L[cl], [4, 96])
    shade = np.clip((L - lo) / (hi - lo), 0, 1)
    core = calpha > 0.9                    # the anti-aliased rim is dark in the painting; borrow shading from the cloud body
    near = cv2.dilate(np.where(core, shade, 0).astype(np.float32), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11)))
    shade = np.where(core, shade, np.maximum(shade, near))
    return sky, calpha, shade

def build_emissive(im_bgr):
    """Canopy stripes of the station: orange/yellow, in the canopy box -> glow at night."""
    x0, x1, y0, y1 = 1040, 2010, 1330, 1440
    hsv = cv2.cvtColor(im_bgr, cv2.COLOR_BGR2HSV).astype(np.float32)
    h, s, v = hsv[..., 0], hsv[..., 1] / 255, hsv[..., 2] / 255
    m = ((h < 30) & (s > 0.45) & (v > 0.6)).astype(np.float32)
    box = np.zeros_like(m); box[y0:y1, x0:x1] = 1
    return cv2.GaussianBlur(m * box, (0, 0), 1.2)

def render(img_bgr, masks, emis, e, ha, moon_ph, stars, grain):
    sky, calpha, shade = masks
    img = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB).astype(np.float32) / 255
    X = np.arange(W, dtype=np.float32)[None, :]; Y = np.arange(H, dtype=np.float32)[:, None]
    zen, hor = [c / 255 for c in _interp([(a, b, c) for a, b, c in STOPS], e)]
    t = (Y / HOR).clip(0, 1)[..., None] ** 1.2
    sky_rgb = np.broadcast_to(zen * (1 - t) + hor * t, (H, W, 3)).copy()

    sx = W * (0.5 + 0.46 * math.sin(ha))
    sy = HOR - (HOR - 140) * (max(e, 0) / 70.0) ** 0.7 if e >= 0 else HOR + 6 * (-e)

    gk = smoothstep(-9, -1, e) * (1 - smoothstep(5, 18, e))
    glow = np.exp(-((X - sx) / 700.0) ** 2) * np.exp(-np.clip(HOR - Y, 0, None) / 260.0)
    warm = smoothstep(-2, 6, e)
    sky_rgb += (glow * gk * 0.85)[..., None] * (np.array([1.0, 0.50, 0.26]) * (1 - warm) + np.array([1.0, 0.78, 0.52]) * warm)

    night = smoothstep(-8, -16, e)
    if night > 0.01:
        from dynsky import star_layer
        # stars are drawn on a 1920x1080 canvas in dynsky; reuse by resizing the layer
        sl = cv2.resize(star_layer_scaled(stars), (W, H), interpolation=cv2.INTER_LINEAR)
        fade = np.clip(1 - (Y / HOR) ** 3, 0, 1) ** 0.6
        sky_rgb += (sl * fade * night * (1 - calpha))[..., None] * np.array([0.85, 0.92, 1.0])

    if -e > 3:                                                          # moon, real phase
        mx = W * (0.5 + 0.46 * math.sin(ha + math.pi)); my = HOR - (HOR - 160) * (min(-e, 60) / 70.0) ** 0.7
        R = 44.0; dx = (X - mx) / R; dy = (Y - my) / R; rr = dx * dx + dy * dy
        nz = np.sqrt(np.clip(1 - rr, 0, 1)); a = 2 * math.pi * moon_ph
        lam = np.clip(dx * math.sin(a) + nz * (-math.cos(a)), 0, 1)
        disk = smoothstep(1.05, 0.95, np.sqrt(rr)); tone = 0.06 + 0.94 * smoothstep(0.0, 0.10, lam)
        lit = (1 - math.cos(a)) / 2
        mf = smoothstep(3, 10, -e) * night * smoothstep(0.03, 0.14, lit)
        rm = np.hypot(X - mx, Y - my)
        sky_rgb += (np.exp(-(rm / 130.0) ** 1.3) * 0.18 * mf * max(lit, 0.2))[..., None] * np.array([0.7, 0.8, 1.0])
        sky_rgb = sky_rgb * (1 - (disk * mf)[..., None]) + (disk * mf * tone)[..., None] * np.array([0.93, 0.95, 1.0])

    # clouds: painted shading kept, colours follow the light
    lit_c = _interp(CLOUD_LIT, e)[0] / 255
    amb = zen * 0.55 + hor * 0.45
    shade_c = amb * 0.9 + lit_c * 0.18
    s = shade[..., None]
    cloud_rgb = shade_c * (1 - s) + lit_c * s
    cloud_rgb = cloud_rgb * (1 + 0.0)
    ca = calpha[..., None]
    sky_full = sky_rgb * (1 - ca) + cloud_rgb * ca

    w_native = float(np.exp(-((e - E_NATIVE) / 11.0) ** 2))             # keep the painting as-is in the afternoon
    sky_full = sky_full * (1 - w_native) + img * w_native
    sky_full = np.clip(sky_full, 0, 1)

    if e > -2.5:                                                        # sun: glow over everything, disc behind clouds
        r_ = np.hypot(X - sx, Y - sy); vis = smoothstep(-2.5, 0.5, e)
        halo = np.exp(-(r_ / 230.0) ** 1.2) * 0.55 + np.exp(-(r_ / 760.0)) * 0.18
        disk = smoothstep(50, 43, r_) * (1 - calpha)
        hot = np.array([1.0, 0.90, 0.70]) * (1 - smoothstep(0, 18, e)) + np.array([1.0, 0.97, 0.88]) * smoothstep(0, 18, e)
        sky_full = sky_full + (halo * vis * (1 - 0.5 * calpha))[..., None] * hot * np.array([1.0, 0.85, 0.6]) * 0.9
        sky_full = sky_full * (1 - (disk * vis)[..., None]) + (disk * vis)[..., None] * hot * 1.15
        sky_full = np.clip(sky_full, 0, 1)

    # foreground relighting
    gain, tint, sat = _interp([(a, (b,), (c[0], c[1], c[2]), (d,)) for a, b, c, d in GRADE], e)
    fg = img * gain[0] * tint
    lum = fg.mean(axis=2, keepdims=True)
    fg = lum + (fg - lum) * sat[0]
    nz_ = smoothstep(-5, -14, e)
    if nz_ > 0.01 and emis is not None:                                  # station canopy lights up at night
        em = emis[..., None]
        glow_big = cv2.GaussianBlur(emis, (0, 0), 14)[..., None]
        fg = fg + (em * 0.55 + glow_big * 0.9) * nz_ * np.array([1.0, 0.68, 0.34])
    fg = np.clip(fg, 0, 1)

    m = sky[..., None]
    out = sky_full * m + fg * (1 - m) + grain * m
    return cv2.cvtColor((np.clip(out, 0, 1) * 255).astype(np.uint8), cv2.COLOR_RGB2BGR)

_star_cache = {}
def star_layer_scaled(stars):
    """Stars generated in the 1080p space of dynsky, drawn at phase 0 (stills don't twinkle)."""
    key = id(stars)
    if key not in _star_cache:
        import dynsky
        _star_cache[key] = dynsky.star_layer(stars, 0.0)
    return _star_cache[key]


KEYFRAMES = [   # name, anchor, minutes offset from the anchor (same schedule as dynsky-build)
    ("night-a",  "MID",     0), ("night-b",  "SR", -170), ("predawn",  "SR",  -75),
    ("blue-am",  "SR",    -35), ("pre-rise", "SR",   -8), ("sunrise",  "SR",   12),
    ("morning",  "SR",     60), ("forenoon", "SR",  170), ("noon",     "NOON",  0),
    ("afternoon","SS",   -170), ("late-pm",  "SS",  -75), ("golden",   "SS",  -35),
    ("sunset",   "SS",     -8), ("dusk-a",   "SS",   12), ("dusk-b",   "SS",   45),
    ("night-c",  "SS",    110),
]
