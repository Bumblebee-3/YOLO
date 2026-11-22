<a id="top"></a>

<div align="center">

<a href="https://github.com/Bumblebee-3/YOLO/stargazers">
  <img alt="Stars" src="https://img.shields.io/github/stars/Bumblebee-3/YOLO?style=for-the-badge&logo=github&logoColor=081217&label=STARS&labelColor=0db2ff&color=ff7166">
</a>
<a href="https://github.com/Bumblebee-3/YOLO/commits/main">
  <img alt="Last commit" src="https://img.shields.io/github/last-commit/Bumblebee-3/YOLO?style=for-the-badge&logo=git&logoColor=081217&labelColor=0db2ff&color=ff7166">
</a>
<a href="LICENSE">
  <img alt="License" src="https://img.shields.io/github/license/Bumblebee-3/YOLO?style=for-the-badge&labelColor=0db2ff&color=ff7166">
</a>

</div>

###### _<div align="right"><sub>// design by Bumblebee-3</sub></div>_

<!-- TODO: banner, ~1600x600. A clean desktop screenshot with the clock widget and visualizer works great. -->
![yolo_banner](docs/assets/banner.png)
<div align="center">

<br>

<a href="#installation"><img alt="Installation" src="https://img.shields.io/badge/01-INSTALLATION-081217?style=for-the-badge&labelColor=0db2ff"></a>
<a href="#features"><img alt="Features" src="https://img.shields.io/badge/02-FEATURES-081217?style=for-the-badge&labelColor=0db2ff"></a>
<a href="#wallpapers"><img alt="Wallpapers" src="https://img.shields.io/badge/03-WALLPAPERS-081217?style=for-the-badge&labelColor=0db2ff"></a>
<a href="#styles"><img alt="Styles" src="https://img.shields.io/badge/04-STYLES-081217?style=for-the-badge&labelColor=0db2ff"></a>
<br>
<a href="#keybindings"><img alt="Keybindings" src="https://img.shields.io/badge/05-KEYBINDINGS-081217?style=for-the-badge&labelColor=ff7166"></a>
<a href="#updating"><img alt="Updating" src="https://img.shields.io/badge/06-UPDATING-081217?style=for-the-badge&labelColor=ff7166"></a>
<a href="#contributing"><img alt="Contributing" src="https://img.shields.io/badge/07-CONTRIBUTING-081217?style=for-the-badge&labelColor=ff7166"></a>
<a href="#credits"><img alt="Credits" src="https://img.shields.io/badge/08-CREDITS-081217?style=for-the-badge&labelColor=ff7166"></a>

<br>

</div>



<div align="center">

<img alt="Arch" src="https://img.shields.io/badge/Arch_Linux-081217?style=for-the-badge&logo=archlinux&logoColor=0db2ff">
<img alt="Hyprland" src="https://img.shields.io/badge/Hyprland-081217?style=for-the-badge&logo=hyprland&logoColor=0db2ff">
<img alt="Quickshell" src="https://img.shields.io/badge/Quickshell-081217?style=for-the-badge&logo=qt&logoColor=ff7166">
<img alt="Waybar" src="https://img.shields.io/badge/Waybar-081217?style=for-the-badge&logo=wayland&logoColor=ff7166">
<img alt="Rofi" src="https://img.shields.io/badge/Rofi-081217?style=for-the-badge&logo=gnometerminal&logoColor=0db2ff">

</div>

<br>

**YOLO** (Your Own Linux Overhaul) is a wallpaper-driven Hyprland desktop for Arch. Pick a wallpaper, and the bar, launcher, terminal, notifications, lock screen, login screen, GTK/Qt apps and even Firefox all recolor to match.

<!-- TODO: showcase video or GIF. On GitHub you can drag an .mp4 into the editor and paste the generated user-attachments URL on its own line, it embeds as a player. -->
<https://github.com/user-attachments/assets/REPLACE-ME>

<br>

<a id="installation"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=INSTALLATION" width="450"/>

---

YOLO targets an **x86-64 Arch Linux** install with a working internet connection, a normal user with `sudo`, and `python`. Other distros are not supported, and the installer refuses to run without `/etc/arch-release`.

> [!IMPORTANT]
> Wallpapers are stored with **Git LFS**. Run `git lfs pull` after cloning or you will get tiny text pointer files instead of images. The collections take about 1.2 GiB in the checkout and another 1.2 GiB once installed.

> [!CAUTION]
> The installer upgrades your system with pacman, switches your display manager to **SDDM** (effective next boot), installs sudo rules for the greeter theme, and builds SwayOSD from source. Your previous display manager and boot target are recorded in `/var/backups/yolo/RUN/service-state.txt` so you can roll back.

> [!WARNING]
> The `hw-zenbook` tier is for the matching ASUS Zenbook only (display scaling, stylus, NumberPad, power limits). Leave it off on any other machine.

```shell
sudo pacman -S --needed git git-lfs base-devel
git clone https://github.com/Bumblebee-3/YOLO.git ~/YOLO
cd ~/YOLO
git lfs pull
./install.sh --dry-run   # preview, changes nothing
./install.sh             # the real thing
```

Reboot, then pick **YOLO (Hyprland)** in SDDM.

> [!TIP]
> Want extras? Tiers stack: `./install.sh touch extra dev`
>
> | Tier | Adds |
> |---|---|
> | `core` | Always on. Desktop, greeter, widgets, OSK, wallpapers, recording tools |
> | `touch` | Hyprgrass gestures + Hyprspace overview |
> | `hw-zenbook` | Zenbook-only profile (includes `touch`) |
> | `extra` | KDE Connect, scrcpy, Android tools, Memoria clipboard |
> | `dev` | git, ShellCheck, StyLua |

> [!NOTE]
> Want to see exactly what lands where first? `./install.sh --stage "$PWD/local/preview"` writes a full copy into `local/preview/` without touching your system.

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="features"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=FEATURES" width="450"/>

---

<div align="center">
<table>
<tr>
<td align="center" width="33%">
<b>Wallpaper colors</b><br><br>
One palette extracted from the wallpaper feeds ~12 apps. Change the image, everything follows.
</td>
<td align="center" width="33%">
<b>Sky that tells time</b><br><br>
<code>dynsky</code> renders the real sun, moon phase and stars for your location and crossfades through the day.
</td>
<td align="center" width="33%">
<b>Touch ready</b><br><br>
On-screen keyboard, Hyprgrass gestures, bottom-swipe overview, hold-to-confirm power menu.
</td>
</tr>
<tr>
<td align="center">
<b>Tahoe-style login</b><br><br>
Custom SDDM greeter with animated wallpaper, battery, session picker and a virtual keyboard.
</td>
<td align="center">
<b>Screen recorder</b><br><br>
Region capture with mic or system audio, pause/resume, a REC overlay, and one-click GIF export.
</td>
<td align="center">
<b>Keybinding editor</b><br><br>
Remap anything from a GUI. Your changes live outside the repo, so updates never clobber them.
</td>
</tr>
<tr>
<td align="center">
<b>Safe installer</b><br><br>
Dry-run, staging, per-file backups, restore mode. Nothing is replaced without a copy.
</td>
<td align="center">
<b>Live widgets</b><br><br>
QuickShell clock, System Core stats, Now Playing and a cava visualizer, all palette-aware.
</td>
<td align="center">
<b>Update notifier</b><br><br>
Checks GitHub every six hours and offers a one-click update in Kitty.
</td>
</tr>
</table>
</div>

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="wallpapers"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=WALLPAPERS" width="450"/>

---

Press `Super + W` to open the picker. Static images live in `~/.config/yolo/wallpapers/oledwall` and animated GIFs in `~/.config/yolo/wallpapers/animwall`. To bring over a personal collection from an older installation, copy its files into the matching folder. Keep any adjacent `.dynsky` directories with their wallpapers.

Picking one regenerates the palette and re-themes Waybar, Rofi, SwayNC, Kitty, btop, Fastfetch, GTK 3/4, Qt 5/6, KDE, Hyprland borders, Hyprlock, SDDM, and Firefox (when [pywalfox](https://github.com/Frewacom/pywalfox) is installed).

### Palette from a single image

<div align="center">

[![accent](https://placehold.co/130x30/0bbfd6/081217?text=accent&font=Oswald)](#wallpapers)
[![accent2](https://placehold.co/130x30/1194a5/ebf9ff?text=accent2&font=Oswald)](#wallpapers)
[![highlight](https://placehold.co/130x30/79cdfc/081217?text=highlight&font=Oswald)](#wallpapers)
[![warn](https://placehold.co/130x30/20c7fc/081217?text=warn&font=Oswald)](#wallpapers)
[![fg](https://placehold.co/130x30/eef5f6/081217?text=fg&font=Oswald)](#wallpapers)

</div>

<sub>Example from the default Aurora wallpaper. Every wallpaper generates its own set.</sub>

<a id="styles"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=STYLES" width="450"/>

---

<!-- TODO: swap in real screenshots. Same filenames or edit the paths. -->

<div align="center"><table><tr><td>Wallpaper Picker</td><td>App Launcher</td></tr><tr><td>
<img src="docs/assets/wall_picker.png"/></td><td>
<img src="docs/assets/launcher.png"/></td></tr>
<tr><td>Emoji Picker</td><td>Notification Center</td></tr><tr><td>
<img src="docs/assets/emoji.png"/></td><td>
<img src="docs/assets/notifications.png"/></td></tr>
</table></div>

<div align="center"><table><tr>Lock &amp; Login</tr><tr><td>
<img src="docs/assets/lock.png"/></td><td>
<img src="docs/assets/greeter.png"/></td></tr></table></div>

<div align="center"><table><tr>Touch</tr><tr><td>
<img src="docs/assets/osk.png"/></td><td>
<img src="docs/assets/powermenu.png"/></td><td>
<img src="docs/assets/overview.png"/></td></tr></table></div>

<div align="center"><table><tr>Tools</tr><tr><td>
<img src="docs/assets/keybind_editor.png"/></td><td>
<img src="docs/assets/recorder.png"/></td><td>
<img src="docs/assets/btop_fastfetch.png"/></td></tr></table></div>

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="keybindings"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=KEYBINDINGS" width="450"/>

---

Press `Super + Shift + K` any time to open the keybindings editor. It also opens automatically on your first login.

<div align="center">

| Keys | Action | Keys | Action |
|:---|:---|:---|:---|
| <kbd>Super</kbd> + <kbd>Q</kbd> | Terminal | <kbd>Super</kbd> + <kbd>W</kbd> | Wallpaper picker |
| <kbd>Super</kbd> + <kbd>A</kbd> | App launcher | <kbd>Super</kbd> + <kbd>L</kbd> | Lock screen |
| <kbd>Super</kbd> + <kbd>E</kbd> | File manager | <kbd>Super</kbd> + <kbd>C</kbd> | Close window |
| <kbd>Super</kbd> + <kbd>F</kbd> | Browser | <kbd>Super</kbd> + <kbd>U</kbd> | Toggle floating |
| <kbd>Super</kbd> + <kbd>V</kbd> | Clipboard history | <kbd>Super</kbd> + <kbd>J</kbd> | Switch tiling layout |
| <kbd>Super</kbd> + <kbd>.</kbd> | Emoji picker | <kbd>Super</kbd> + <kbd>1</kbd>..<kbd>0</kbd> | Workspaces |
| <kbd>Print</kbd> | Region screenshot | <kbd>Super</kbd> + <kbd>S</kbd> | Special workspace |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Esc</kbd> | Task manager | <kbd>Super</kbd> + <kbd>M</kbd> | Exit Hyprland |

</div>

Screen recording starts unassigned. Bind `record`, `record-mic`, `record-system` and `record-pause` in the editor.

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="updating"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=UPDATING" width="450"/>

---

YOLO checks GitHub two minutes after login and every six hours after that. Choose **Install update** in the notification to run the updater in Kitty.

Doing it by hand:

```shell
cd ~/YOLO
git pull
git lfs pull
./install.sh -r          # restore files only, skips packages
```

Run a full `./install.sh` (without `-r`) whenever a package list changes. Use the same tiers you installed with.

> [!IMPORTANT]
> Any config you edited gets overwritten if it is listed in `manifest.psv`. Every replaced file is backed up first to `~/.config/cfg_backups/RUN/` (user) or `/var/backups/yolo/RUN/` (system). Put permanent personal tweaks in `local/home/`, which wins on restore and is git-ignored.

<details>
<summary><b>Recovering a replaced file</b></summary>

```shell
cp -a --remove-destination \
  ~/.config/cfg_backups/RUN/.config/kitty/kitty.conf \
  ~/.config/kitty/kitty.conf
```

Replace `RUN` with the ID the installer printed. For a broken login screen, switch to a TTY, read `service-state.txt`, disable SDDM and re-enable your previous manager.

</details>

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="contributing"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=CONTRIBUTING" width="450"/>

---

PRs and issues are welcome, whether it is code, testing on different hardware, or docs.

1. Fork, then branch from `main`.
2. Install the `dev` tier for ShellCheck and StyLua.
3. Test with `./install.sh --dry-run` and `--stage` before touching a real system.
4. New file? Add it to `manifest.psv` under the right tier.
5. Run `shellcheck` on shell scripts and `stylua` on Lua.
6. In the PR, say what you changed and what hardware you tested on.

<details>
<summary><b>Repo layout</b></summary>

```
YOLO/
├── install.sh        entry point
├── manifest.psv      tier -> source -> destination
├── lib/              installer helpers (deploy.py, pkg.sh, ...)
├── hooks/            service enabling
├── pkgs/             package lists per tier
├── configs/          dotfiles -> ~/.config and ~/.local
├── profiles/         hw-zenbook, touch, extra
├── system/           SDDM theme, session entry, sudoers, libexec
├── themes/           oledwall + animwall
└── vendor/swayosd    pinned SwayOSD fork
```

</details>

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="star_history"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=0DB2FF&vCenter=true&width=435&height=25&lines=STARS" width="450"/>

[![Stargazers over time](https://starchart.cc/Bumblebee-3/YOLO.svg?background=%23081217&axis=%23ebf9ff&line=%230db2ff)](https://starchart.cc/Bumblebee-3/YOLO)

---


### Contributors

<a href="https://github.com/Bumblebee-3/YOLO/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Bumblebee-3/YOLO" />
</a>

### Assets and license


#### Wallpaper Credits

A huge thanks to the photographers and creators whose work helps bring YOLO's desktop to life.

The following wallpapers are sourced from [Unsplash](https://unsplash.com) and made available under the [Unsplash License](https://unsplash.com/license).

| Filename | Wallpaper | Creator | Source |
|:---|:---|:---|:---|
| `eclipse.jpg` | Solar Eclipse | Bryan Goff | [Unsplash](https://unsplash.com/photos/we1ky8_ZTHg) |
| `smoke-silhouette.jpg` | Silhouette with Smoke | Aziz Acharki | [Unsplash](https://unsplash.com/photos/7nsqPSnYCoY) |
| `northern-lights.jpg` | Northern Lights | Jonatan Pie | [Unsplash](https://unsplash.com/photos/3l3RwQdHRHg) |
| `outer-space.jpg` | Outer Space | NASA | [Unsplash](https://unsplash.com/photos/Q1p7bh3SHj8) |
| `starry-silhouette.jpg` | Silhouette Under the Stars | Greg Rakozy | [Unsplash](https://unsplash.com/photos/oMpAz-DN-9I) |
| `molten-lava.jpg` | Molten Lava - Kalapana | Buzz Andersen | [Unsplash](https://unsplash.com/photos/E4944K_4SvI) |

These wallpapers remain the work of their respective creators and are distributed under the Unsplash License, independently of YOLO's GPL-3.0-or-later software license.

Code is released under **GPL-3.0-or-later** (see [LICENSE](LICENSE)). <!-- TODO: add the LICENSE file -->

---

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>