install_packages() {
    local tier pkg helper build_dir
    local -a official=() community=()
    for tier in "${tiers[@]}"; do
        while read -r pkg; do
            case "$pkg" in
                ''|'#'*) continue ;;
                aur:*) community+=("${pkg#aur:}") ;;
                *) official+=("$pkg") ;;
            esac
        done < "$repo/pkgs/$tier.lst"
    done
    if (( plan )) || [[ -n $stage ]]; then
        log "Arch packages: ${official[*]}"
        (("${#community[@]}" == 0)) || log "AUR packages: ${community[*]}"
        return
    fi
    sudo pacman -Syu --needed "${official[@]}"
    (("${#community[@]}" > 0)) || return 0
    if command -v paru >/dev/null; then helper=paru
    elif command -v yay >/dev/null; then helper=yay
    else
        sudo pacman -S --needed git base-devel
        build_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"
        (cd "$build_dir/paru-bin" && makepkg -si)
        helper=paru
    fi
    "$helper" -S --needed "${community[@]}"
}

source_key() {
    (cd "$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) |
        sha256sum | cut -d' ' -f1
}

build_circle_search() {
    if ((plan)) || [[ -n $stage ]]; then
        log "Build plan: compile Circle Search for the native Rust target and deploy ~/.local/bin/circle."
        return
    fi
    local target build_dir="$repo/local/circle-build"
    target=$(rustc --print host-tuple)
    local key stamp="$build_dir/$target/yolo-source"
    key=$(source_key "$repo/vendor/circle-search")
    circle_binary="$build_dir/$target/release/circle-search"
    if [[ -x $circle_binary && -f $stamp && $(<"$stamp") == "$key" ]]; then
        log "Reusing Circle Search ($target)."
        return
    fi
    cargo build --locked --release --manifest-path "$repo/vendor/circle-search/Cargo.toml" \
        --target "$target" --target-dir "$build_dir"
    circle_binary="$build_dir/$target/release/circle-search"
    "$circle_binary" --version
    printf '%s\n' "$key" > "$stamp"
}

build_yolo_swayosd() {
    local build_dir="$repo/vendor/swayosd/build"
    if ((plan)) || [[ -n $stage ]]; then
        return
    fi
    [[ -f "$repo/vendor/swayosd/meson.build" ]] || die "Bundled SwayOSD source is missing"
    command -v meson >/dev/null || die "meson is required to build bundled SwayOSD"
    meson setup "$build_dir" "$repo/vendor/swayosd" --buildtype release --prefix /usr/local
    meson compile -C "$build_dir"
    sudo meson install -C "$build_dir"
    sudo systemctl daemon-reload
}
