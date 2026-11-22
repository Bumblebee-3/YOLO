#!/usr/bin/python -I
"""Authenticated X11 session entry for the single-output YOLO handoff test."""
from io import BytesIO
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import syslog
import tempfile
import time

from PIL import Image, ImageChops, ImageOps
from Xlib import X, XK, display, error
from Xlib.ext import composite, res

HERE = Path(__file__).resolve().parent
POSTER = Path("/usr/share/sddm/themes/yolo/Backgrounds/login-preview.jpg")


def status(message):
    syslog.syslog(syslog.LOG_INFO, "yolo-handoff: " + message)
    print(message, flush=True)


def desktop(pidfile, *args):
    Path(pidfile).write_text(str(os.getpid()))
    os.environ.update(XDG_SESSION_TYPE="wayland", XDG_CURRENT_DESKTOP="Hyprland",
                      PATH=str(Path.home() / ".local/bin") + ":" + os.environ["PATH"])
    library = HERE / "libaquamarine.so.15"
    if not library.exists():
        raise RuntimeError(f"Missing private test library: {library}")
    # Limit the library override to this compositor executable and its linked dependencies.
    os.execl("/lib64/ld-linux-x86-64.so.2", "ld-linux-x86-64.so.2", "--library-path",
             str(HERE), "/usr/bin/Hyprland", "--config",
             args[0] if args else str(Path.home() / ".config/hypr/hyprland.lua"))


def poster_visible(pixmap, expected):
    # Sample the host's actual X output, even while the cover obscures it.
    width, height = expected.size
    good = total = 0
    for row in range(1, 10):
        y = row * height // 10
        raw = pixmap.get_image(0, y, width, 1, X.ZPixmap, 0xffffffff)
        line = Image.frombytes("RGB", (width, 1), raw.data, "raw", "BGRX")
        for col in range(1, 20):
            x = col * width // 20
            target = expected.getpixel((x, y))
            if max(target) < 40:
                continue
            good += max(abs(a - b) for a, b in zip(line.getpixel((x, 0)), target)) <= 32
            total += 1
    return total >= 8 and good >= total * 0.80


def desktop_visible(pidfile, expected):
    if not pidfile.is_file():
        return False
    pid = pidfile.read_text()
    for lock in (Path(os.environ["XDG_RUNTIME_DIR"]) / "hypr").glob("*/hyprland.lock"):
        try:
            lines = lock.read_text().splitlines()
        except FileNotFoundError:
            continue
        if len(lines) < 2 or lines[0] != pid:
            continue
        try:
            shot = subprocess.run(["grim", "-s", "0.1", "-t", "ppm", "-"],
                                  env=dict(os.environ, WAYLAND_DISPLAY=lines[1]),
                                  capture_output=True, timeout=1)
        except subprocess.TimeoutExpired:
            return False
        if shot.returncode:
            return False
        actual = Image.open(BytesIO(shot.stdout)).convert("RGB").resize(expected.size)
        diff = ImageChops.difference(actual, expected).tobytes()
        return sum(max(diff[i:i + 3]) <= 25 for i in range(0, len(diff), 3)) >= 0.8 * len(diff) / 3
    return False


def supervise(args):
    # Independent deadline also covers a blocked X request or renderer startup.
    with tempfile.TemporaryDirectory(dir=os.environ["XDG_RUNTIME_DIR"]) as tmp:
        ready = Path(tmp) / "ready"
        proc = subprocess.Popen([sys.executable, "-I", __file__, "--run", str(ready), *args],
                                start_new_session=True)
        try:
            deadline = time.monotonic() + 15
            while proc.poll() is None and not ready.exists():
                if time.monotonic() >= deadline:
                    raise RuntimeError("Startup watchdog expired; returning to SDDM")
                time.sleep(0.1)
            return proc.wait()
        finally:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
                time.sleep(0.25)
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            proc.wait()


def run(ready, args):
    if not POSTER.is_file():
        raise RuntimeError(f"Missing login wallpaper: {POSTER}")
    if subprocess.check_output(["pacman", "-Q", "aquamarine"], text=True).split()[1].split("-")[0] != "0.16.0":
        raise RuntimeError("Rebuild the handoff for the installed Aquamarine version")
    outputs = subprocess.check_output(["xrandr", "--listactivemonitors"], text=True)
    if outputs.splitlines()[0].split()[-1] != "1":
        raise RuntimeError("This experiment requires one active monitor")
    x = display.Display()
    screen = x.screen()
    root = screen.root
    w, h = root.get_geometry().width, root.get_geometry().height
    busy = error.CatchError(error.BadAccess)
    root.change_attributes(event_mask=X.SubstructureRedirectMask, onerror=busy)
    x.sync()
    if busy.get_error():
        raise RuntimeError("A window manager already owns this X display")
    subprocess.run(["feh", "--no-fehbg", "--bg-fill", str(POSTER)], check=True)
    cover = root.create_window(0, 0, w, h, 0, X.CopyFromParent, X.InputOutput,
                               X.CopyFromParent, override_redirect=True, background_pixmap=X.ParentRelative)
    escape = x.keysym_to_keycode(XK.XK_Escape)
    root.grab_key(escape, X.AnyModifier, False, X.GrabModeAsync, X.GrabModeAsync)
    cover.map()
    x.sync()
    status("Showing login wallpaper")
    expected = ImageOps.fit(Image.open(POSTER).convert("RGB"), (w, h))
    thumbnail = expected.resize((64, 40))
    env = os.environ.copy()
    env.pop("WAYLAND_DISPLAY", None)
    with tempfile.TemporaryDirectory(dir=os.environ["XDG_RUNTIME_DIR"]) as temp:
        pidfile = Path(temp) / "desktop-pid"
        host = subprocess.Popen(["weston", "-B", "x11", "--renderer=gl", "--shell=kiosk-shell.so",
                                 "-S", str(Path(temp) / "wayland"), "--no-config", "-i", "0", "--width", str(w), "--height", str(h),
                                 "--", sys.executable, "-I", __file__, "--desktop", str(pidfile), *args], env=env)
        window = pixmap = None
        try:
            deadline = time.monotonic() + 12
            while time.monotonic() < deadline:
                if host.poll() is not None:
                    raise RuntimeError(f"Weston exited during startup: {host.returncode}")
                while x.pending_events():
                    event = x.next_event()
                    if event.type == X.KeyPress and event.detail == escape:
                        raise RuntimeError("Handoff cancelled with Escape")
                    if event.type == X.MapRequest:
                        client = event.window
                        ids = x.res_query_client_ids([dict(client=client.id, mask=res.LocalClientPIDMask)]).ids
                        if window is None and any(host.pid in entry.value for entry in ids):
                            window = client
                            window.composite_redirect_window(composite.RedirectAutomatic)
                            window.configure(x=0, y=0, width=w, height=h, border_width=0)
                        client.configure(sibling=cover, stack_mode=X.Below)
                        client.map()
                        x.sync()
                        if client == window:
                            pixmap = window.composite_name_window_pixmap()
                            if pixmap.get_geometry().depth != 24:
                                raise RuntimeError("This test requires a 24-bit Xorg screen")
                if pixmap is not None and desktop_visible(pidfile, thumbnail) and poster_visible(pixmap, expected):
                    pixmap.free()
                    window.composite_unredirect_window(composite.RedirectAutomatic)
                    root.ungrab_key(escape, X.AnyModifier)
                    recovery = X.ControlMask | X.Mod1Mask
                    for locks in (0, X.LockMask, X.Mod2Mask, X.LockMask | X.Mod2Mask):
                        root.grab_key(escape, recovery | locks, False, X.GrabModeAsync, X.GrabModeAsync)
                    window.configure(stack_mode=X.Above)
                    window.set_input_focus(X.RevertToParent, X.CurrentTime)
                    cover.destroy()
                    root.change_attributes(event_mask=0)
                    x.sync()
                    ready.touch()
                    status("Revealed rendered desktop")
                    while host.poll() is None:
                        while x.pending_events():
                            key = x.next_event()
                            if key.type == X.KeyPress and key.detail == escape and key.state & recovery == recovery:
                                status("Recovery shortcut pressed; returning to SDDM")
                                return 0
                        select.select([x.fileno()], [], [], 0.5)
                    return host.returncode
                time.sleep(0.08)
            raise RuntimeError("Desktop did not present the login wallpaper before timeout")
        finally:
            if host.poll() is None:
                host.terminate()
            x.close()


if __name__ == "__main__":
    try:
        if sys.argv[1:2] == ["--desktop"]:
            desktop(*sys.argv[2:])
        if sys.argv[1:2] == ["--run"]:
            sys.exit(run(Path(sys.argv[2]), sys.argv[3:]))
        sys.exit(supervise(sys.argv[1:]))
    except Exception as exc:
        status(str(exc))
        sys.exit(1)
