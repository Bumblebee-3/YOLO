#!/bin/bash
# Manual four-mode control for this Zenbook. `get` never applies settings.
set -Eeuo pipefail

MODES=(power-saver balanced performance power-saver)
ICONS=("󰌪" "󰛲" "󱐌" "󰂃")
LABELS=("Power Saver" "Balanced" "Performance" "Extreme Saver")
CLASSES=(powersave balanced performance extreme)
RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
STATE_FILE="$RUNTIME_DIR/powermode_state"
ERROR_FILE="$RUNTIME_DIR/powermode.error"
RAPL=/sys/class/powercap/intel-rapl/intel-rapl:0
CPU=/sys/devices/system/cpu
ASPM=/sys/module/pcie_aspm/parameters/policy

# Preserve the previous script's normal-mode limits. These are user-set
# values, NOT discovered firmware defaults. Extreme uses 15 W / 20 W.
NORMAL_PL1=115000000
NORMAL_PL2=115000000

read_state() {
    CURRENT=1
    STATE_STATUS=missing
    if [[ -r $STATE_FILE ]]; then
        local saved
        saved=$(<"$STATE_FILE")
        if [[ $saved =~ ^[0-3]$ ]]; then
            CURRENT=$saved
            STATE_STATUS=valid
        else
            STATE_STATUS=invalid
        fi
    elif [[ -e $STATE_FILE ]]; then
        STATE_STATUS=unreadable
    fi
}

render() {
    local warning=${1:-} tooltip=${LABELS[$CURRENT]}
    if [[ -n $warning ]]; then tooltip+=" — $warning"; fi
    jq -cn --arg text "${ICONS[$CURRENT]}" --arg tooltip "$tooltip" \
        --arg class "${CLASSES[$CURRENT]}" --arg warning "$warning" \
        '{text: ($text + (if $warning == "" then "" else " ⚠" end)),
          tooltip: $tooltip,
          class: (if $warning == "" then $class else [$class,"error"] end)}'
}

read_state
ACTION=${1:-get}
if [[ $ACTION == get ]]; then
    warning=""
    if [[ -r $ERROR_FILE ]]; then warning=$(<"$ERROR_FILE"); fi
    if ! actual=$(powerprofilesctl get); then
        warning="${warning:+$warning }Power daemon unavailable; selected mode is not verified."
    elif [[ $actual != "${MODES[$CURRENT]}" ]]; then
        warning="${warning:+$warning }Daemon reports $actual; run powermode.sh apply to reapply this mode."
    elif [[ $STATE_STATUS == missing ]]; then
        warning="No mode has been applied this session."
    elif [[ $STATE_STATUS != valid ]]; then
        warning="Saved mode is invalid or unreadable; select a mode to repair it."
    fi
    render "$warning"
    exit 0
fi

case "$ACTION" in
    toggle|apply) ;;
    set)
        case "${2:-}" in
            0|power-saver|powersave) REQUESTED=0 ;;
            1|balanced) REQUESTED=1 ;;
            2|performance) REQUESTED=2 ;;
            3|extreme) REQUESTED=3 ;;
            *) printf 'Unknown mode: %s\n' "${2:-}" >&2; exit 2 ;;
        esac
        ;;
    *) printf 'Usage: %s {get|toggle|apply|set MODE}\n' "$0" >&2; exit 2 ;;
esac

# Serialize rapid clicks; only mutating commands create the lock.
[[ -d $RUNTIME_DIR && -O $RUNTIME_DIR ]] || {
    printf 'A user-owned runtime directory is required.\n' >&2; exit 1;
}
exec 9>"$RUNTIME_DIR/powermode.lock"
flock -x 9
read_state
case "$ACTION" in
    toggle) TARGET=$(( (CURRENT + 1) % 4 )) ;;
    apply) TARGET=$CURRENT ;;
    set) TARGET=$REQUESTED ;;
esac

TEMP_STATE=""
LAST_ACTION="checking the power daemon"
LAST_ERROR=""
fail() {
    local status=$?
    trap - ERR
    local message="Failed to apply ${LABELS[$TARGET]} while $LAST_ACTION. ${LAST_ERROR:+$LAST_ERROR }Hardware may be partially changed. Reapply or select a mode again."
    printf '%s\n' "$message" >&2
    printf '%s\n' "$message" > "$ERROR_FILE"
    if [[ -n $TEMP_STATE ]]; then rm -f -- "$TEMP_STATE"; fi
    render "$message"
    exit "$status"
}
trap fail ERR

write_value() {
    local path=$1 value=$2 actual
    LAST_ACTION="setting $path to $value"
    LAST_ERROR=""
    actual=$(cat -- "$path")
    if [[ $actual == "$value" ]]; then return 0; fi
    if LAST_ERROR=$(sudo -n /usr/local/libexec/zenbook-power-write "$value" "$path" 2>&1); then
        LAST_ERROR=""
    else
        return 1
    fi
    actual=$(cat -- "$path")
    if [[ $actual != "$value" ]]; then
        LAST_ERROR="Requested $value, read back $actual."
        printf 'Setting did not stick: %s (requested %s, read %s)\n' "$path" "$value" "$actual" >&2
        return 1
    fi
}

write_aspm() {
    local value=$1 actual
    LAST_ACTION="setting ASPM to $value"
    LAST_ERROR=""
    actual=$(cat -- "$ASPM")
    if [[ $actual == "$value" || $actual == *"[$value]"* ]]; then return 0; fi
    if LAST_ERROR=$(sudo -n /usr/local/libexec/zenbook-power-write "$value" "$ASPM" 2>&1); then
        LAST_ERROR=""
    else
        return 1
    fi
    actual=$(cat -- "$ASPM")
    [[ $actual == "$value" || $actual == *"[$value]"* ]]
}

# Fail visibly before hardware writes when the daemon is unavailable.
powerprofilesctl get >/dev/null

if [[ $TARGET != 3 ]]; then
    # Restore cores BEFORE the daemon sets EPP/EPB on their CPU policies.
    for n in {1..13}; do write_value "$CPU/cpu$n/online" 1; done
fi
LAST_ACTION="selecting daemon profile ${MODES[$TARGET]}"
powerprofilesctl set "${MODES[$TARGET]}"

if [[ $TARGET == 3 ]]; then
    write_value "$RAPL/constraint_0_power_limit_uw" 15000000
    write_value "$RAPL/constraint_1_power_limit_uw" 20000000
else
    write_value "$RAPL/constraint_0_power_limit_uw" "$NORMAL_PL1"
    write_value "$RAPL/constraint_1_power_limit_uw" "$NORMAL_PL2"
fi

for policy in "$CPU"/cpufreq/policy*; do
    # This Intel system has one policy per CPU. Inactive policy directories
    # can remain present while their attributes return ENODEV after offlining.
    index=${policy##*/}
    online="$CPU/cpu${index#policy}/online"
    if [[ -r $online && $(<"$online") == 0 ]]; then continue; fi
    if [[ $TARGET == 3 ]]; then
        write_value "$policy/scaling_max_freq" 1200000
    else
        write_value "$policy/scaling_max_freq" "$(cat "$policy/cpuinfo_max_freq")"
    fi
done

if [[ $TARGET == 3 ]]; then
    # Set EPB before offlining, while every currently online core is accessible.
    for bias in "$CPU"/cpu*/power/energy_perf_bias; do
        online=${bias%/power/energy_perf_bias}/online
        if [[ -r $online && $(<"$online") == 0 ]]; then continue; fi
        write_value "$bias" 15
    done
    # Preserve the user's selection: CPU0, CPU14 and CPU15 stay online.
    # CPU0 remains a P-core; this is not an LP-E-only configuration.
    for n in {1..13}; do write_value "$CPU/cpu$n/online" 0; done
    write_aspm powersupersave
else
    # The daemon owns normal-mode EPP/EPB; do not replace it with EPB=6.
    write_aspm default
fi

# Publish the new mode only after every requested setting succeeded. Atomic
# replacement also avoids following an existing /tmp state-file symlink.
TEMP_STATE=$(mktemp "${STATE_FILE}.XXXXXX")
LAST_ACTION="saving the selected mode"
printf '%s\n' "$TARGET" > "$TEMP_STATE"
mv -Tf -- "$TEMP_STATE" "$STATE_FILE"
TEMP_STATE=""
rm -f -- "$ERROR_FILE"
CURRENT=$TARGET
trap - ERR
render
