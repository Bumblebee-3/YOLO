# YOLO · Your Own Linux Overhaul

YOLO stages and installs a wallpaper-driven Hyprland desktop on x86-64 Arch Linux. The core profile includes Kitty, Dolphin, Waybar, Rofi, SwayNC, SwayOSD, QuickShell widgets and keyboard, Hyprlock, Fastfetch, GTK and Qt palettes, and the customized Astronaut SDDM greeter.

## Install on the Dell

Start from a bootable Arch installation with internet access, Python, sudo, and a normal user in a working login session. For the Dell transfer archive, run `tar --zstd -xf YOLO.tar.zst` and `cd YOLO`. You can also copy the project or clone your own remote. For Git clones with LFS-managed media, run `git lfs pull` first. The wallpaper collections occupy about 1.2 GiB in the checkout and another 1.2 GiB in the installed home.

```sh
./install.sh --dry-run
./install.sh
```

Run the installer as the desktop user. It upgrades Arch with pacman, installs the selected packages, copies the payload and enables SDDM for the next graphical boot. It records the prior display manager and boot target. Reboot and choose **YOLO (Hyprland)** in SDDM. That session starts the bundled Lua config explicitly. The Dell uses its detected displays and power profiles. Leave the Zenbook tier off on the Dell.

| Selection | Packages and behavior |
|---|---|
| `core` (always included) | Desktop, greeter, widgets, on-screen keyboard, wallpaper collections, recording tools and everyday controls. All packages from Arch repositories. |
| `touch` | Plugin build dependencies and first-login setup for Hyprgrass and Hyprspace. A Kitty window runs the setup so hyprpm can show its trust and build prompts. |
| `hw-zenbook` | Includes touch. Adds the original eDP-1 scale, rotation, mapped touchscreen and stylus, UP5401EA NumberPad and four power modes with model-specific limits. Use only on the matching hardware. |
| `extra` | KDE Connect, scrcpy, Android tools and Memoria clipboard integration. |
| `dev` | Git, ShellCheck and StyLua for editing the framework. |

Example for the original laptop: `./install.sh hw-zenbook extra`. A tier with AUR entries uses paru or yay. If neither is installed, the installer builds paru-bin as the invoking user. Package and build prompts remain interactive. Optional browser/editor shortcuts work when their applications are already installed.

## Restore, customize and recover

- Run `git pull` in your clone, then `./install.sh -r` with the same tiers to restore files and enable services. Run a full install when a package list changes. Tiers are additive. Omitting a previously installed tier leaves its files and packages on disk.
- Preview changes with `./install.sh -r --dry-run hw-zenbook`. To inspect a real copy with no package, service or sudo actions, run `./install.sh --stage "$PWD/local/preview"`. The preview has separate `home/` and `root/` trees.
- `manifest.psv` maps each tier and repository source to a home or system destination. Directory entries deploy individual files. Before replacing a changed file, YOLO copies the original, including symlinks, into `~/.config/cfg_backups/RUN/` or `/var/backups/yolo/RUN/`. The installer prints the run ID. Re-running the same restore skips matching files. Unrelated neighboring files are preserved.
- To recover a replaced user file, copy it back from its backup, e.g. `cp -a --remove-destination ~/.config/cfg_backups/RUN/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf`, substituting the printed run ID. Use the matching system backup with sudo for system files. Newly added files have no predecessor. Package upgrades are managed by pacman. For display-manager recovery, use a TTY, inspect `/var/backups/yolo/RUN/service-state.txt`, disable SDDM and enable the recorded previous manager, then restore the recorded default target.
- Put persistent machine-specific files under `local/home/`, mirroring the home directory. Their versions take precedence on restore. The local folder is Git-ignored. The initial working copy also preserves the pre-conversion project payload in `local/original/`. For distribution, copy the project **excluding local/** or share the tracked tree.
- Home deployments target the conventional `~/.config` and `~/.local` layout used by these scripts. Parent-directory symlinks require review. File replacements are atomic; an interrupted install can be rerun.

## Desktop behavior

**Super+Q** opens Kitty, **Super+A** opens the launcher, **Super+W** opens the wallpaper picker, **Super+L** locks, and **Super+E** opens Dolphin. **Super+M** exits Hyprland. KDE Connect uses **Super+Shift+M** to resolve the original duplicate binding. On the Zenbook, **Super+R** rotates the display, touchscreen and stylus together. The keyboard icon in Waybar toggles the QuickShell OSK.

The touch setup uses the installed Bumblebee-3 Hyprgrass fork at `3b311c0e694b299844b34ef7935b5aa08772cd45` and Hyprspace at `8345bf6f623d486ca3f87f416ccf1412416eef08`. The reference compositor is Hyprland 0.57.2. Compositor updates may require compatible plugin revisions. After an unsuccessful build or an update, run `~/.local/bin/yolo-plugins` inside Hyprland. Check `hyprpm list` and `hyprctl configerrors`. The OSK and Rofi namespace exclusions, workspace swipe, bottom-edge overview gestures and recording gestures come from the active Lua config. Keyboard shortcuts work independently of the plugins.

The generic profile uses an available backlight and the power-profiles daemon. NetworkManager's terminal UI opens from Waybar. To reuse the optional phone key, export `YOLO_ANDROID_DEVICE` with your own adb host and port in the session environment. To use an existing Bibata installation, set `YOLO_CURSOR=Bibata-Modern-Ice`. Adwaita is the bundled profile's cursor default.

## Wallpaper and login theme

Static images live in `themes/oledwall/` and animated media in `themes/animwall/`. Matching `.dynsky/` directories include their schedules and rendered keyframes. The scheduler uses the latitude and longitude in each schedule. The wallpaper picker updates the bar, launcher, terminal, notifications, lock screen, Qt/GTK colors and greeter. Firefox integration activates when pywalfox is available. The initial desktop and greeter use the same Nissan GIF.

The installer supplies a separate `yolo` SDDM theme, a Qt virtual keyboard, the Tahoe battery QML module and a YOLO session entry. Existing high-priority `/etc/sddm.conf` theme or input-method keys are updated after backup. The publisher accepts image bytes and a validated palette from the desktop user's narrowly scoped sudo rule. Its output directory and filenames are fixed. The Zenbook-only power helper has its own sudo rule. Bootloader and kernel settings are outside the default manifest.

The bundled SwayOSD source is the `Bumblebee-3/SwayOSD` fork at commit `95c6fe3`. The installer builds it into `/usr/local` after the package dependencies are installed, then enables its user service. Brightness bindings use SwayOSD's wildcard backlight selection, so they work with different laptop backlight names. SwayOSD requires a network connection the first time it builds its Rust dependencies.

QuickShell's System Core and Now Playing panels derive their position, width, and scale from the active monitor. The SDDM theme leaves screen dimensions empty so the greeter uses the actual display size. If an older deployed copy still has fixed `ScreenWidth` or `ScreenHeight` values, run `./install.sh -r` to replace it.

The TahoeBattery QML module and Circle utility are the x86-64 binaries from the reference system. Greeter testing used SDDM 0.21 and Qt 6.12. The imported greeter theme includes its upstream license. The personal wallpaper and font collection came from the reference machine. Check redistribution rights before publishing those assets. Set up Git LFS before the first commit if hosting this collection on GitHub; individual GIFs exceed GitHub's ordinary file size limit.

## Dell smoke test

1. Verify SDDM displays the login fields and virtual keyboard. Select YOLO and launch Kitty and Rofi.
2. Run `hyprctl configerrors`, then check audio, brightness, lid toggle and the Waybar keyboard button.
3. Pick a static wallpaper and an animated one. Check the QuickShell palette, GTK/Qt colors, Fastfetch, Hyprlock, and SDDM on the next logout.
4. Change one deployed config, run `./install.sh -r`, and confirm the previous contents appear under the printed backup ID.
