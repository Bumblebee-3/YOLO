"""Time-of-day renderer for an animated wallpaper: procedural sky, sun, moon (real phase),
stars and foreground relighting.  Used by dynsky-build."""
import math
import numpy as np, cv2

H, W = 1080, 1920
HORIZON = 446                      # y of the city-haze line in the source frames

def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)

# ------------------------------------------------------------------ astronomy
def sun_state(dt, lat, lon, tz_hours):
    """dt: naive local datetime -> (elevation_deg, hour_angle_rad)."""
    n = dt.timetuple().tm_yday
    g = 2 * math.pi / 365 * (n - 1 + (dt.hour - 12) / 24)
    eqt = 229.18 * (0.000075 + 0.001868*math.cos(g) - 0.032077*math.sin(g)
                    - 0.014615*math.cos(2*g) - 0.040849*math.sin(2*g))
    decl = (0.006918 - 0.399912*math.cos(g) + 0.070257*math.sin(g) - 0.006758*math.cos(2*g)
            + 0.000907*math.sin(2*g) - 0.002697*math.cos(3*g) + 0.00148*math.sin(3*g))
    tst = dt.hour*60 + dt.minute + dt.second/60 + eqt + 4*lon - 60*tz_hours
    ha = math.radians(tst/4 - 180)
    la = math.radians(lat)
    s = math.sin(la)*math.sin(decl) + math.cos(la)*math.cos(decl)*math.cos(ha)
    return math.degrees(math.asin(max(-1, min(1, s)))), ha

def sun_events(date, lat, lon, tz):
    """-> dict of minutes-from-local-midnight: SR, SS, NOON, MID"""
    import datetime as D
    es = []
    for m in range(1440):
        dt = D.datetime(date.year, date.month, date.day, m // 60, m % 60)
        es.append(sun_state(dt, lat, lon, tz)[0])
    thr = -0.833
    sr = next((m for m in range(1, 1440) if es[m-1] < thr <= es[m]), 360)
    ss = next((m for m in range(1, 1440) if es[m-1] >= thr > es[m]), 1080)
    noon = int(np.argmax(es))
    return {"SR": sr, "SS": ss, "NOON": noon, "MID": (noon + 720) % 1440}

def moon_phase(dt):
    jd = dt.toordinal() + 1721424.5 + (dt.hour + dt.minute / 60) / 24
    return ((jd - 2451550.1) % 29.530588) / 29.530588        # 0 new, 0.5 full

# ------------------------------------------------------------------ colours by sun elevation
STOPS = [
    (-18, (  2,   4,  12), (  8,  14,  34)),
    (-12, (  6,  12,  36), ( 30,  48,  92)),
    ( -7, ( 18,  34,  84), (110,  86, 128)),
    ( -2, ( 40,  68, 120), (255, 132,  88)),
    (  3, ( 66, 112, 178), (255, 190, 130)),
    (  9, ( 60, 124, 198), (196, 216, 238)),
    ( 25, ( 40, 112, 208), (168, 210, 246)),
    ( 60, ( 30, 100, 205), (150, 200, 245)),
]
def sky_colors(e):
    e = max(STOPS[0][0], min(STOPS[-1][0], e))
    for (e0, z0, h0), (e1, z1, h1) in zip(STOPS, STOPS[1:]):
        if e0 <= e <= e1:
            t = (e - e0) / (e1 - e0)
            return (np.array(z0)*(1-t) + np.array(z1)*t) / 255.0, (np.array(h0)*(1-t) + np.array(h1)*t) / 255.0

# ------------------------------------------------------------------ sky mask (from the mean frame: no flicker)
def make_mask(mean_bgr):
    v = cv2.cvtColor(mean_bgr, cv2.COLOR_BGR2HSV)[..., 2].astype(np.float32) / 255
    yy = np.arange(H)[:, None] * np.ones((1, W))
    m = ((yy < HORIZON) & (v > 0.30)).astype(np.uint8) * 255
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((7, 7), np.uint8))
    n, lbl = cv2.connectedComponents(m)
    keep = np.zeros_like(m)
    for k in range(1, n):
        comp = lbl == k
        if comp[0, :].any() and comp.sum() > 5000:
            keep[comp] = 255
    keep = cv2.erode(keep, np.ones((3, 3), np.uint8))
    return cv2.GaussianBlur(keep, (0, 0), 1.6).astype(np.float32) / 255

def make_strip(mean_bgr):
    """Bright haze strip just under the horizon line: treated as sky so it follows the lighting."""
    L = cv2.cvtColor(mean_bgr, cv2.COLOR_BGR2GRAY).astype(np.float32) / 255
    Y = np.arange(H, dtype=np.float32)[:, None]
    ramp = np.clip((HORIZON + 20 - Y) / 20, 0, 1) * (Y >= HORIZON - 2)
    return (ramp * smoothstep(0.40, 0.62, cv2.GaussianBlur(L, (0, 0), 3))).astype(np.float32)

# ------------------------------------------------------------------ stars
def make_stars(seed=7, count=900):
    rng = np.random.default_rng(seed)
    return (rng.uniform(0, W, count), (rng.uniform(0, 1, count) ** 0.8) * HORIZON,
            rng.uniform(0.25, 1.0, count) ** 2.2, rng.integers(1, 5, count), rng.uniform(0, 2*np.pi, count))

def star_layer(stars, phase):
    xs, ys, br, k, ph = stars
    layer = np.zeros((H, W), np.float32)
    tw = 0.82 + 0.18 * np.sin(2*np.pi*(k*phase) + ph)              # integer k => loops seamlessly
    for x, y, b, t in zip(xs, ys, br, tw):
        xi, yi = int(x), int(y)
        layer[yi, xi] = max(layer[yi, xi], b*t)
        if b > 0.45:
            layer[yi, min(W-1, xi+1)] = max(layer[yi, min(W-1, xi+1)], b*t*0.5)
            layer[min(H-1, yi+1), xi] = max(layer[min(H-1, yi+1), xi], b*t*0.5)
    return cv2.GaussianBlur(layer, (0, 0), 0.8) * 2.2

# ------------------------------------------------------------------ foreground
def grade_foreground(img, e, hor, X, Y):
    day = smoothstep(-4, 14, e); night = smoothstep(-5, -14, e)
    x = np.power(np.clip(img, 0, 1), 1.0 - 0.18 * day)
    lum = x.mean(axis=2, keepdims=True)
    lift = 1 + 0.60 * day * (1 - smoothstep(0.30, 0.85, lum))        # lift shadows, leave highlights alone
    out = x * lift * (1 - 0.42 * night)
    tint = 1 + night*np.array([-0.10, -0.03, 0.12]) + day*np.array([0.06, 0.02, -0.06])
    out = out * tint
    l2 = out.mean(axis=2)
    hp = np.clip(l2 - cv2.GaussianBlur(l2, (0, 0), 6) - 0.04, 0, 1)   # city lights pop at night, fade by day
    out = out + hp[..., None] * (0.9*night - 0.7*day) * 2.0
    # daylight haze on the far hills/city (not on the car)
    car = smoothstep(980, 880, X) * smoothstep(440, 520, Y)
    far = (1 - car) * np.where(Y >= HORIZON, np.exp(-np.clip(Y - HORIZON, 0, None) / 130.0),
                                  0.35 + 0.65 * np.exp(-np.clip(HORIZON - Y, 0, None) / 70.0))
    out = out * (1 - day * 0.42 * far)[..., None] + (day * 0.42 * far)[..., None] * hor * 0.95
    return np.clip(out, 0, 1)

def render_frame(frame_bgr, mask, strip, e, ha, moon_ph, stars, phase, grain):
    frame_bgr = cv2.bilateralFilter(frame_bgr, 7, 14, 5)
    img = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB).astype(np.float32) / 255
    zen, hor = sky_colors(e)
    X = np.arange(W, dtype=np.float32)[None, :]; Y = np.arange(H, dtype=np.float32)[:, None]
    t = (Y / HORIZON).clip(0, 1)[..., None] ** 1.25
    grad = np.broadcast_to(zen * (1 - t) + hor * t, (H, W, 3)).copy()

    sx = W * (0.5 + 0.46 * math.sin(ha))
    sy = HORIZON - (HORIZON - 80) * (max(e, 0) / 70.0) ** 0.7 if e >= 0 else HORIZON + 4 * (-e)

    glow_k = smoothstep(-9, -1, e) * (1 - smoothstep(4, 16, e))
    glow = np.exp(-((X - sx) / 520.0) ** 2) * np.exp(-np.clip(HORIZON - Y, 0, None) / 150.0)
    warm = smoothstep(-2, 6, e)
    grad += (glow * glow_k * 0.9)[..., None] * (np.array([1.0, 0.52, 0.28]) * (1 - warm) + np.array([1.0, 0.80, 0.55]) * warm)

    L = img.mean(axis=2); Lb = cv2.GaussianBlur(L, (0, 0), 40)
    T = np.clip((L - Lb) / (Lb + 0.05), -0.7, 0.7)
    d = smoothstep(-6, 6, e)
    sky = grad * (1 + T[..., None] * 0.9 * (1 - d))
    sky += np.clip(-T, 0, 1)[..., None] * 0.55 * d

    if e > -2.5:                                                        # sun
        r = np.hypot(X - sx, Y - sy); vis = smoothstep(-2.5, 0.5, e)
        halo = np.exp(-(r / 150.0) ** 1.2) * 0.55 + np.exp(-(r / 520.0)) * 0.18
        disk = smoothstep(34, 29, r)
        hot = np.array([1.0, 0.90, 0.70]) * (1 - smoothstep(0, 18, e)) + np.array([1.0, 0.97, 0.88]) * smoothstep(0, 18, e)
        sky += (halo * vis)[..., None] * hot * np.array([1.0, 0.85, 0.6]) * 0.9
        sky = sky * (1 - (disk * vis)[..., None]) + (disk * vis)[..., None] * hot * 1.15

    night = smoothstep(-8, -16, e)
    if night > 0.01:                                                    # stars
        fade = np.clip(1 - (Y / HORIZON) ** 3, 0, 1) ** 0.6
        sky += (star_layer(stars, phase) * fade * night)[..., None] * np.array([0.85, 0.92, 1.0])
    if -e > 3:                                                          # moon, real phase
        mx = W * (0.5 + 0.46 * math.sin(ha + math.pi)); my = HORIZON - (HORIZON - 90) * (min(-e, 60) / 70.0) ** 0.7
        R = 30.0; dx = (X - mx) / R; dy = (Y - my) / R
        rr = dx * dx + dy * dy
        nz = np.sqrt(np.clip(1 - rr, 0, 1))
        a = 2 * math.pi * moon_ph
        lam = np.clip(dx * math.sin(a) + nz * (-math.cos(a)), 0, 1)
        disk = smoothstep(1.06, 0.94, np.sqrt(rr))
        tone = 0.06 + 0.94 * smoothstep(0.0, 0.10, lam)
        lit = (1 - math.cos(a)) / 2
        mf = smoothstep(3, 10, -e) * night * smoothstep(0.03, 0.14, lit)
        r = np.hypot(X - mx, Y - my)
        sky += (np.exp(-(r / 90.0) ** 1.3) * 0.18 * mf * max(lit, 0.2))[..., None] * np.array([0.7, 0.8, 1.0])
        sky = sky * (1 - (disk * mf)[..., None]) + (disk * mf * tone)[..., None] * np.array([0.93, 0.95, 1.0])

    w_native = float(np.exp(-((e + 4) / 3.2) ** 2))                      # keep the original look at blue hour
    sky = np.clip(sky * (1 - w_native) + img * w_native, 0, 1)

    fg = grade_foreground(img, e, hor, X, Y)
    m = np.maximum(mask, strip * (1 - mask))[..., None]
    out = np.clip(sky * m + fg * (1 - m) + grain * m, 0, 1)
    return cv2.cvtColor((out * 255).astype(np.uint8), cv2.COLOR_RGB2BGR)
