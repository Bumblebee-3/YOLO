die() { printf 'YOLO: %s\n' "$*" >&2; exit 1; }
log() { printf 'YOLO: %s\n' "$*"; }
usage() {
    echo 'Usage: ./install.sh [-r] [--dry-run] [--stage DIR] [core] [extra] [dev] [touch] [hw-zenbook]'
    echo 'Core is always included. -r restores files and skips packages. Stage simulates deployment in DIR.'
}
