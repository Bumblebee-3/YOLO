#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
for lib in common pkg restore hooks; do source "$repo/lib/$lib.sh"; done
restore_only=0 plan=0 stage=''
tiers=(core)
while (($#)); do
    case "$1" in
        -r) restore_only=1 ;;
        --dry-run) plan=1 ;;
        --stage) shift; [[ -n ${1:-} ]] || die 'Missing staging path'; stage=$(realpath -m -- "$1") ;;
        -h|--help) usage; exit ;;
        core) ;;
        extra|dev|touch|hw-zenbook) [[ " ${tiers[*]} " == *" $1 "* ]] || tiers+=("$1") ;;
        *) die "Unknown option or tier: $1" ;;
    esac
    shift
done
if [[ " ${tiers[*]} " == *" hw-zenbook "* && " ${tiers[*]} " != *" touch "* ]]; then tiers+=(touch); fi
run="$(date -u +%Y%m%dT%H%M%S%NZ)-$$"
if (( ! plan )) && [[ -z $stage ]]; then
    (( EUID != 0 )) || die 'Run as the target desktop user with sudo access'
    [[ -f /etc/arch-release ]] || die 'YOLO targets Arch Linux'
    exec 9<"$HOME"
    flock -n 9 || die 'Another YOLO installation for this user is running'
fi
if (( ! restore_only )); then install_packages; fi
if (( ! restore_only )); then build_yolo_swayosd; fi
restore_config
run_hooks
if (( ! plan )) && [[ -z $stage && -e $repo/.git ]]; then
    state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/yolo
    mkdir -p "$state_dir"
    state_tmp=$(mktemp "$state_dir/update.XXXXXX")
    {
        printf '%s\n' "$repo" "$(git -C "$repo" rev-parse HEAD)"
        { printf '%s\n' "${tiers[@]}"; if [[ -f $state_dir/update ]]; then tail -n +3 "$state_dir/update"; fi; } | sort -u
    } > "$state_tmp"
    mv -f "$state_tmp" "$state_dir/update"
    if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
        systemctl --user import-environment WAYLAND_DISPLAY
        systemctl --user start yolo-update.timer
    fi
fi
log "Backup ID for replaced files: $run"
