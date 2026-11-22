# Persistent display handoff experiment

Run `python experiments/display-handoff/probe.py` from a Wayland session. A temporary window hosts two nested Hyprland instances. Close the test with Ctrl+C. The probe uses grim, Pillow, swaybg, and QuickShell. Its temporary home directories live under YOLO's local directory.

The outer compositor displays a wallpaper cover. The inner compositor starts with a deliberately different wallpaper. The probe samples both compositor outputs, checks that the cover is still visible after the inner wallpaper renders, removes the cover, observes the changed host output, and checks that the outer wallpaper returns when the inner compositor exits. Samples measure rendered pixels at checkpoints. Physical scanout and uninterrupted frame-by-frame presentation need separate tests.

## Login integration

Both test compositors run as the invoking user. A production host must run outside the desktop user's account, own the seat throughout login and logout, and obtain the authentication result from a privileged login manager. Retain PAM session setup, credential establishment, logind registration and teardown. A successful authentication must precede launching any user-controlled program.

The desktop should receive a restricted Wayland connection with only the input, output and rendering interfaces needed for nesting. It must not inherit the host's control socket, session bus, screencopy or layer-shell privileges. The host must control focus and reveal, with a host-observed presented desktop buffer. On desktop crash or logout, revoke that connection and restore the greeter before accepting another login. The sample cover is visual only.

Before offering an installer profile, test wrong passwords, failed session startup, crash recovery, logout, multi-output hotplug and scaling, suspend/resume, touchscreen input, and GPU acceleration on the Dell and Zenbook. Verify the real panel across login with an external recording.

## Authenticated Zenbook experiment (Arch x86-64, one active monitor)

Select **YOLO (display handoff test)** from the square session button on the YOLO greeter and sign in normally. The entry goes in SDDM's **xsessions** directory. SDDM authenticates the user and opens an X11 session on its existing Xorg display. The session paints the login preview, runs Weston’s OpenGL X11 backend, and starts the user's configured Hyprland inside Weston. It samples both the desktop and the X window before lifting the cover. Press Escape during startup or Ctrl+Alt+Escape after reveal to return to SDDM. An independent 15-second watchdog ends a stalled startup. Session events are logged with the prefix `yolo-handoff:`. To return to the native desktop, log out and select **YOLO (Hyprland)**.

This is an experimental nested session. Input, GPU outputs, and the logind session type differ from native Wayland. In particular, verify locking before using it for an unattended session. Do not install this through the core manifest. The test uses Weston, feh, grim, xorg-xrandr, python-xlib, and python-pillow on a machine already running YOLO.

Build the matching private Aquamarine library from the YOLO checkout as a normal user. The tested version binds xdg-shell v6 even when the host offers v5. This patch negotiates the supported seat, shell, and compositor versions for these hosts.

```sh
git clone --depth 1 --branch v0.16.0 https://github.com/hyprwm/aquamarine local/handoff-aquamarine
git -C local/handoff-aquamarine apply ../../experiments/display-handoff/aquamarine-0.16.0.patch
cmake -S local/handoff-aquamarine -B local/handoff-aquamarine/build -G Ninja
cmake --build local/handoff-aquamarine/build --target aquamarine
sudo install -Dm755 local/handoff-aquamarine/build/libaquamarine.so.0.16.0 /usr/local/libexec/yolo-handoff/libaquamarine.so.15
sudo install -Dm755 experiments/display-handoff/session.py /usr/local/libexec/yolo-handoff/session.py
sudo install -Dm644 experiments/display-handoff/yolo-handoff.desktop /usr/share/xsessions/yolo-handoff.desktop
```

The separate entry leaves the native session available. To uninstall after logging out of the experiment:

```sh
sudo rm -f /usr/share/xsessions/yolo-handoff.desktop /usr/local/libexec/yolo-handoff/{session.py,libaquamarine.so.15}
sudo rmdir /usr/local/libexec/yolo-handoff
```
