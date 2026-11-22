#!/usr/bin/env python3
"""Exercise the display handoff inside a window of an existing Wayland session."""
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
from contextlib import ExitStack

from PIL import Image, ImageChops, ImageStat
from io import BytesIO

repo = Path(__file__).resolve().parents[2]
poster = repo / "configs/.local/share/yolo/login-wall.jpg"


def wait_for_frame(env, processes, expected=None):
    for _ in range(100):
        for process in processes:
            if process.poll() is not None:
                raise RuntimeError(f"{process.args[0]} exited with {process.returncode}")
        result = subprocess.run(["grim", "-t", "png", "-"], env=env,
                                capture_output=True, timeout=5)
        if result.returncode == 0:
            image = Image.open(BytesIO(result.stdout)).convert("RGB").resize((32, 24))
            if expected is not None:
                if max(ImageStat.Stat(ImageChops.difference(image, expected)).mean) < 8:
                    return image
            elif max(ImageStat.Stat(image).stddev) > 20:
                return image
        time.sleep(0.1)
    raise RuntimeError("Timed out waiting for wallpaper pixels")


def shutdown(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()


def launch(stack, env, *args):
    proc = subprocess.Popen(args, env=env, start_new_session=True)
    stack.callback(shutdown, proc)
    return proc


def compositor(stack, base, name, parent):
    root = base / name
    root.mkdir(mode=0o700)
    env = dict(os.environ, HOME=str(root), XDG_RUNTIME_DIR=str(root),
               WAYLAND_DISPLAY=str(parent), XDG_CACHE_HOME=str(root / "cache"),
               XDG_CONFIG_HOME=str(root / "config"), XDG_DATA_HOME=str(root / "data"),
               XDG_STATE_HOME=str(root / "state"), HYPRLAND_NO_SD_NOTIFY="1",
               HYPRLAND_NO_SD_VARS="1", DBUS_SESSION_BUS_ADDRESS="unix:path=/dev/null")
    env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
    config = root / "hyprland.lua"
    config.write_text('hl.config({misc={disable_hyprland_logo=true, disable_splash_rendering=true}, animations={enabled=false}})\n'
                      'hl.monitor({output="",mode="preferred",position="auto",scale=1})\n')
    proc = launch(stack, env, "Hyprland", "--config", str(config))
    for _ in range(100):
        sockets = [s for s in root.glob("wayland-*") if s.is_socket()]
        if sockets:
            env["WAYLAND_DISPLAY"] = str(sockets[0])
            return env, proc
        if proc.poll() is not None:
            break
        time.sleep(0.1)
    raise RuntimeError(f"{name} compositor did not open its display")


def main():
    parent = Path(os.environ["XDG_RUNTIME_DIR"]) / os.environ["WAYLAND_DISPLAY"]
    if not parent.is_socket():
        raise RuntimeError("Run from a Wayland desktop")
    with tempfile.TemporaryDirectory(dir=repo / "local") as tmp, ExitStack() as stack:
        host, hp = compositor(stack, Path(tmp), "host", parent)
        cover = launch(stack, dict(host, YOLO_POSTER=poster.as_uri()), "quickshell", "-p",
                       str(Path(__file__).with_name("Cover.qml").resolve()))
        host_frame = wait_for_frame(host, [hp, cover])
        still = launch(stack, host, "swaybg", "-m", "fill", "-i", str(poster))
        print("Host wallpaper rendered", flush=True)
        with ExitStack() as session:
            desk, dp = compositor(session, Path(tmp), "desktop", host["WAYLAND_DISPLAY"])
            # A distinct image makes a premature reveal detectable.
            wallpaper = launch(session, desk, "swaybg", "-m", "fill", "-i",
                               str(repo / "themes/oledwall/eclipse.jpg"))
            wait_for_frame(desk, [dp, wallpaper])
            wait_for_frame(host, [hp, cover], host_frame)
            shutdown(cover)
            for _ in range(100):
                visible = wait_for_frame(host, [hp, dp])
                if max(ImageStat.Stat(ImageChops.difference(visible, host_frame)).mean) > 12:
                    break
                time.sleep(0.05)
            else:
                raise RuntimeError("Desktop was not revealed")
            print("Nested desktop wallpaper rendered", flush=True)
        wait_for_frame(host, [hp, still], host_frame)
        print("Host survived desktop exit", flush=True)


if __name__ == "__main__":
    main()
