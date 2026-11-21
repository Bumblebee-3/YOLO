#!/bin/bash

# Path to save the cover
COVER_PATH="$XDG_RUNTIME_DIR/spotube_cover.png"

# Listen for artUrl changes
playerctl metadata --follow --format '{{mpris:artUrl}}' | while read -r url; do
    if [[ "$url" == http* ]]; then
        # Download the image
        curl -s "$url" -o "$COVER_PATH"
        swaync-client -rs
    elif [[ "$url" == file://* ]]; then
        # Copy local file to the standard path
        cp "${url#file://}" "$COVER_PATH"
        swaync-client -rs
    fi
done
