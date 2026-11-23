run_hooks() {
    if ((plan)) || [[ -n $stage ]]; then
        log "Service plan: enable SDDM for next boot."
        if [[ " ${tiers[*]} " == *" touch "* ]]; then log "Enable ydotool for the touchscreen keyboard."; fi
    else
        bash "$repo/hooks/enable-services.sh" "$run"
    fi
}
