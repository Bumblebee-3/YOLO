run_hooks() {
    if ((plan)) || [[ -n $stage ]]; then
        log "Service plan: enable SDDM for next boot and ydotool for the user."
    else
        bash "$repo/hooks/enable-services.sh" "$run"
    fi
}
