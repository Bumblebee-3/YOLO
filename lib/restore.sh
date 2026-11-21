restore_config() {
    local scope root home_path=$HOME
    local -a runner flags=()
    ((plan == 0)) || flags+=(--plan)
    [[ -z $stage ]] || home_path="$stage/home"
    for scope in home system; do
        runner=()
        root=$home_path
        if [[ $scope == system ]]; then
            root=${stage:+$stage/root}
            root=${root:-/}
            if [[ -z $stage ]] && (( ! plan )); then runner=(sudo); fi
        fi
        "${runner[@]}" python -I "$repo/lib/deploy.py" --scope "$scope" --root "$root" \
            --home "$home_path" --uid "$(id -u)" --run "$run" "${flags[@]}" "${tiers[@]}"
    done
}
