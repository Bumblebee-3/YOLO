# Persistent display handoff experiment

Run `python experiments/display-handoff/probe.py` from a Wayland session. A temporary window hosts two nested Hyprland instances. Close the test with Ctrl+C. The probe uses grim, Pillow, swaybg, and QuickShell. Its temporary home directories live under YOLO's local directory.

The outer compositor displays a wallpaper cover. The inner compositor starts with a deliberately different wallpaper. The probe samples both compositor outputs, checks that the cover is still visible after the inner wallpaper renders, removes the cover, observes the changed host output, and checks that the outer wallpaper returns when the inner compositor exits. Samples measure rendered pixels at checkpoints. Physical scanout and uninterrupted frame-by-frame presentation need separate tests.

## Login integration

Both test compositors run as the invoking user. A production host must run outside the desktop user's account, own the seat throughout login and logout, and obtain the authentication result from a privileged login manager. Retain PAM session setup, credential establishment, logind registration and teardown. A successful authentication must precede launching any user-controlled program.

The desktop should receive a restricted Wayland connection with only the input, output and rendering interfaces needed for nesting. It must not inherit the host's control socket, session bus, screencopy or layer-shell privileges. The host must control focus and reveal, with a host-observed presented desktop buffer. On desktop crash or logout, revoke that connection and restore the greeter before accepting another login. The sample cover is visual only.

Before offering an installer profile, test wrong passwords, failed session startup, crash recovery, logout, multi-output hotplug and scaling, suspend/resume, touchscreen input, and GPU acceleration on the Dell and Zenbook. Verify the real panel across login with an external recording.
