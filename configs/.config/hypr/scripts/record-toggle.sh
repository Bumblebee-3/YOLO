#!/bin/bash
# usage: record-toggle.sh [silent|mic|sys|pause]
mode=${1:-silent}
qml=~/.config/hypr/scripts/record-border.qml
dir=${XDG_RUNTIME_DIR:-/tmp}/screenrec
state=$dir/state
mkdir -p "$dir" ~/Videos

overlay() {   # overlay <geom> <elapsed-seconds> <paused 0|1>
    pkill -f record-border.qml
    sleep 0.15
    GEOM="$1" ELAPSED="$2" PAUSED="$3" setsid -f quickshell -p "$qml"
}

save() {      # save <acc> <since> <geom> <want: run|pause|stop> <pid>
    printf 'acc=%s\nsince=%s\ngeom=%q\nwant=%s\npid=%s\n' "$1" "$2" "$3" "$4" "$5" > "$state"
}

active() {    # a session is active if the state file exists and its owner is alive
    [ -f "$state" ] || return 1
    . "$state"
    kill -0 "$pid" 2>/dev/null
}

# ---- controller: a session is already running ----
if active; then
    now=$(date +%s)
    if [ "$mode" = pause ]; then
        if [ "$want" = run ]; then                      # pause: finish this part
            acc=$(( acc + now - since ))
            save "$acc" "" "$geom" pause "$pid"
            pkill -INT -x wf-recorder
            overlay "$geom" "$acc" 1
        elif [ "$want" = pause ]; then                  # resume: main loop starts the next part
            save "$acc" "$now" "$geom" run "$pid"
            overlay "$geom" "$acc" 0
        fi
    else                                                # stop
        save "$acc" "$since" "$geom" stop "$pid"
        pkill -INT -x wf-recorder
        pkill -f record-border.qml
    fi
    exit 0
fi

[ "$mode" = pause ] && exit 0                           # nothing to pause

# ---- start a new session ----
geom=$(slurp) || exit 1

case $mode in
    mic) audio=(--audio="$(pactl get-default-source)") ;;
    sys) audio=(--audio="$(pactl get-default-sink).monitor") ;;
    *)   audio=() ;;
esac

stamp=$(date '+%a%d-%m-%y-%H-%M-%S' | tr '[:upper:]' '[:lower:]')
file=~/Videos/rec-$stamp.mp4
parts=~/Videos/.rec-$stamp
mkdir -p "$parts"

save 0 "$(date +%s)" "$geom" run $$
overlay "$geom" 0 0

n=1
while :; do
    wf-recorder -g "$geom" "${audio[@]}" -f "$parts/part-$n.mp4"
    . "$state"
    [ "$want" = pause ] || break                        # stopped (or crashed)
    while [ "$want" = pause ]; do sleep 0.2; . "$state"; done
    [ "$want" = run ] || break                          # stopped while paused
    n=$((n + 1))
done

pkill -f record-border.qml
rm -f "$state"

# ---- join the parts ----
mapfile -t segs < <(printf '%s\n' "$parts"/part-*.mp4 | sort -V)
good=()
for f in "${segs[@]}"; do [ -s "$f" ] && good+=("$f"); done
[ ${#good[@]} -gt 0 ] || { rm -rf "$parts"; exit 0; }

if [ ${#good[@]} -eq 1 ]; then
    mv "${good[0]}" "$file"
else
    for f in "${good[@]}"; do printf "file '%s'\n" "$f"; done > "$parts/list.txt"
    ffmpeg -y -loglevel error -f concat -safe 0 -i "$parts/list.txt" -c copy "$file" || {
        notify-send -u critical -a "Screen recorder" "Joining parts failed" "Parts kept in ~${parts#$HOME}"
        exit 1
    }
fi
rm -rf "$parts"
[ -s "$file" ] || exit 0

# ---- notification ----
notify_open() {   # notify_open <title> <path>
    local act
    act=$(notify-send -a "Screen recorder" -i video-x-generic -A "open=Open" --wait \
        "$1" "Stored at ~${2#$HOME}")
    [ "$act" = open ] && xdg-open "$2"
}

(
    act=$(notify-send -a "Screen recorder" -i video-x-generic \
        -A "open=Open" -A "gif=Convert to GIF" --wait \
        "Recording saved" "Stored at ~${file#$HOME}")
    case $act in
        open) xdg-open "$file" ;;
        gif)
            gif=${file%.mp4}.gif
            notify-send -a "Screen recorder" -t 3000 "Converting to GIF…" "This may take a moment"
            if ffmpeg -y -loglevel error -i "$file" \
                -vf 'fps=15,scale=min(800\,iw):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse' \
                "$gif"; then
                notify_open "GIF saved" "$gif"
            else
                notify-send -u critical -a "Screen recorder" "GIF conversion failed"
            fi ;;
    esac
) &
