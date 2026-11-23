restore_config() {
    local scope root home_path=$HOME
    local -a runner flags=() generated
    ((plan == 0)) || flags+=(--plan)
    [[ -z $stage ]] || home_path="$stage/home"
    for scope in home system; do
        runner=()
        generated=()
        if [[ $scope == home && -n ${circle_binary:-} ]]; then generated+=(--circle-binary "$circle_binary"); fi
        root=$home_path
        if [[ $scope == system ]]; then
            root=${stage:+$stage/root}
            root=${root:-/}
            if [[ -z $stage ]] && (( ! plan )); then runner=(sudo); fi
        fi
        "${runner[@]}" python -I "$repo/lib/deploy.py" --scope "$scope" --root "$root" \
            --home "$home_path" --uid "$(id -u)" --run "$run" "${flags[@]}" "${generated[@]}" "${tiers[@]}"
    done
}
