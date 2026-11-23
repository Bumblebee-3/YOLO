#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
for lib in common pkg restore hooks; do source "$repo/lib/$lib.sh"; done
restore_only=0 plan=0 stage='' circle_binary=''
tiers=(core)
while (($#)); do
    case "$1" in
        -r) restore_only=1 ;;
        --dry-run) plan=1 ;;
        --stage) shift; [[ -n ${1:-} ]] || die 'Missing staging path'; stage=$(realpath -m -- "$1") ;;
        -h|--help) usage; exit ;;
        core) ;;
        extra|dev|touch|hw-zenbook|lower-ram-usage) [[ " ${tiers[*]} " == *" $1 "* ]] || tiers+=("$1") ;;
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
if (( ! restore_only )); then
    build_circle_search
    build_yolo_swayosd
fi
battery_build=''
if (( plan )); then
    log "Build plan: reuse TahoeBattery when source, architecture and Qt match."
else
    battery_stamp="${stage:-${XDG_STATE_HOME:-$HOME/.local/state}}/yolo/tahoe-build"
    battery_key="$(source_key "$repo/plugins/TahoeBattery") $(uname -m) $(pkg-config --modversion Qt6Qml)"
    module="${stage:+$stage/root}/usr/lib/qt6/qml/TahoeBattery"
    if [[ -s $module/libtahoebattery.so && -s $module/qmldir && -f $battery_stamp && $(<"$battery_stamp") == "$battery_key" ]]; then
        log "Reusing installed TahoeBattery."
    else
    battery_build=$(mktemp -d)
    trap 'rm -rf -- "$battery_build"' EXIT
    cmake -S "$repo/plugins/TahoeBattery" -B "$battery_build" -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release
    cmake --build "$battery_build"
    DESTDIR="$battery_build/image" cmake --install "$battery_build"
    fi
fi
restore_config
if [[ -n $battery_build ]] && cmp -s "$module/libtahoebattery.so" "$battery_build/image/usr/lib/qt6/qml/TahoeBattery/libtahoebattery.so" && cmp -s "$module/qmldir" "$repo/plugins/TahoeBattery/qmldir"; then
    mkdir -p "${battery_stamp%/*}"
    printf '%s\n' "$battery_key" > "$battery_stamp"
fi
run_hooks
if (( ! plan )) && [[ -z $stage && -e $repo/.git ]]; then
    state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/yolo
    mkdir -p "$state_dir"
    state_tmp=$(mktemp "$state_dir/update.XXXXXX")
    {
        printf '%s\n' "$repo" "$(git -C "$repo" rev-parse HEAD)"
        { printf '%s\n' "${tiers[@]}"; if [[ -f $state_dir/update ]]; then sed '1,2d; /^lower-ram-usage$/d' "$state_dir/update"; fi; } | sort -u
    } > "$state_tmp"
    mv -f "$state_tmp" "$state_dir/update"
    if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
        systemctl --user import-environment WAYLAND_DISPLAY
        systemctl --user start yolo-update.timer
    fi
fi
log "Backup ID for replaced files: $run"
