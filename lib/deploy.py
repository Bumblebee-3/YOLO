"""Copy individual manifest entries atomically, preserving unrelated files."""
import argparse
import filecmp
import os
import re
import shutil
import stat
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
for option in ("scope", "root", "home", "uid", "run"):
    parser.add_argument("--" + option, required=True)
parser.add_argument("--plan", action="store_true")
parser.add_argument("--battery-image", type=Path)
parser.add_argument("--circle-binary", type=Path)
parser.add_argument("tiers", nargs="+")
args = parser.parse_args()
root = Path(args.root).resolve()
backup = root / (".config/cfg_backups" if args.scope == "home" else "var/backups/yolo") / args.run


def relative(name):
    path = Path(name)
    if path.is_absolute() or ".." in path.parts or not path.parts:
        raise ValueError(f"Expected relative path: {name}")
    return path


def files(source, target):
    if source.is_symlink() or source.is_file():
        yield target, source
    elif source.is_dir():
        for child in sorted(source.iterdir()):
            yield from files(child, target / child.name)
    else:
        raise ValueError(f"Missing manifest source: {source}")


def sddm_config(path):
    # Set both selectors at SDDM's highest configuration priority. A custom
    # ThemeDir or a later vendor drop-in can otherwise select another greeter.
    desired = {"Theme": {"Current": "yolo", "ThemeDir": "/usr/share/sddm/themes"},
               "General": {"InputMethod": "qtvirtualkeyboard"}}
    section = ""
    lines = []
    seen = set()

    def finish_section():
        for key, value in desired.get(section, {}).items():
            if (section, key) not in seen:
                lines.append(f"{key}={value}\n")
                seen.add((section, key))

    for line in (path.read_text().splitlines() if path.exists() else []):
        header = re.match(r"\s*\[([^]]+)\]", line)
        if header:
            finish_section()
            section = header[1]
        key = line.partition("=")[0].strip()
        if "=" in line and key in desired.get(section, {}):
            line = f"{key}={desired[section][key]}"
            seen.add((section, key))
        lines.append(line + "\n")
    finish_section()
    for section, keys in desired.items():
        if not any((section, key) in seen for key in keys):
            lines.append(f"[{section}]\n")
            finish_section()
    return "".join(lines).encode()


def check_parents(path):
    # Existing desktop setups often link a whole config directory. Follow
    # those links when they remain inside the selected deployment root.
    root_resolved = root.resolve()
    parent_resolved = path.parent.resolve(strict=False)
    try:
        parent_resolved.relative_to(root_resolved)
    except ValueError:
        raise ValueError(f"Destination parent resolves outside deployment root: {path.parent}")
    for parent in path.parents:
        if parent == root:
            break
        if parent.exists() and not parent.is_dir():
            raise ValueError(f"Destination parent is not a directory: {parent}")


def deploy(name, source):
    dst = root / name
    check_parents(dst)
    link = None
    data = None
    if source is None:
        if dst.is_symlink():
            raise ValueError(f"Review symlinked SDDM configuration: {dst}")
        data = sddm_config(dst)
        mode = stat.S_IMODE(dst.stat().st_mode) if dst.exists() else 0o644
    else:
        mode = 0o755 if source.stat().st_mode & 0o111 else 0o644
        if source.is_symlink():
            link = os.readlink(source)
            relative(link)
            if dst.is_symlink() and os.readlink(dst) == link:
                return
        elif source.stat().st_size < 2**20:
            raw = source.read_bytes()
            if raw.startswith(b"version https://git-lfs.github.com/spec/v1"):
                raise ValueError(f"Missing Git LFS object: {source}. Run git lfs pull.")
            if b"\0" not in raw:
                data = raw.replace(b"@YOLO_HOME@", os.fsencode(args.home)).replace(b"@YOLO_UID@", args.uid.encode())
        if name.parent == Path("etc/sudoers.d"):
            mode = 0o440

    if dst.exists() and not dst.is_symlink() and not dst.is_file():
        raise ValueError(f"Destination is not a file: {dst}")
    owner_ok = not (args.scope == "system" and root == Path("/") and dst.exists()) or dst.lstat().st_uid == 0
    if owner_ok and link is None and dst.is_file() and not dst.is_symlink() and stat.S_IMODE(dst.stat().st_mode) == mode:
        if (data is not None and dst.read_bytes() == data) or (data is None and filecmp.cmp(source, dst, shallow=False)):
            return
    print(f"{args.scope}/{name}")
    if args.plan:
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".yolo-", dir=dst.parent) as scratch:
        new = Path(scratch) / "new"
        if link is not None:
            new.symlink_to(link)
        else:
            if data is None:
                shutil.copyfile(source, new)
            else:
                new.write_bytes(data)
            new.chmod(mode)
            if name.parent == Path("etc/sudoers.d"):
                subprocess.run(["visudo", "-cf", new], check=True)
        if dst.exists() or dst.is_symlink():
            saved = backup / name
            check_parents(saved)
            backup.mkdir(mode=0o700, parents=True, exist_ok=True)
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, saved, follow_symlinks=False)
            if args.scope == "system" and not saved.is_symlink():
                old = dst.stat()
                os.chown(saved, old.st_uid, old.st_gid)
        os.replace(new, dst)


entries = {}
for line in (repo / "manifest.psv").read_text().splitlines():
    if not line or line.startswith("#"):
        continue
    tier, scope, src, dest = line.split("|")
    if tier in args.tiers and scope == args.scope:
        entries.update(files(repo / relative(src), relative(dest)))
if args.scope == "home" and args.circle_binary:
    entries[Path(".local/bin/circle")] = args.circle_binary
if args.scope == "home" and (repo / "local/home").is_dir():
    for child in sorted((repo / "local/home").iterdir()):
        entries.update(files(child, Path(child.name)))
if args.scope == "system":
    if args.battery_image:
        entries.update(files(args.battery_image, Path()))
    entries[Path("etc/sddm.conf")] = None
    theme = Path("usr/share/sddm/themes/yolo")
    override = theme / "theme.conf.user"
    legacy = root / theme / "Themes/astronaut.conf.user"
    if theme / "theme.conf" in entries and not os.path.lexists(root / override):
        check_parents(legacy)
        if legacy.is_file() and not legacy.is_symlink():
            entries[override] = legacy
for target, source in entries.items():
    deploy(target, source)


# This tier is a run mode. Omitting it on reinstall restores the desktop widgets.
marker = Path(".config/yolo/lower-ram-usage")
if args.scope == "home" and "lower-ram-usage" not in args.tiers and marker not in entries:
    dst = root / marker
    check_parents(dst)
    if os.path.lexists(dst):
        if not (dst.is_symlink() or dst.is_file()):
            raise ValueError(f"Expected a low-RAM marker file: {dst}")
        print(f"remove home/{marker}")
        if not args.plan:
            saved = backup / marker
            check_parents(saved)
            backup.mkdir(mode=0o700, parents=True, exist_ok=True)
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, saved, follow_symlinks=False)
            dst.unlink()
