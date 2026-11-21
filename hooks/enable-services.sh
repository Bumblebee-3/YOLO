#!/usr/bin/env bash
set -euo pipefail
backup="/var/backups/yolo/$1"
sudo install -d -m 0700 "$backup"
# Record boot selection before systemctl changes its aliases.
{
    echo "default-target $(systemctl get-default)"
    echo "display-manager $(readlink /etc/systemd/system/display-manager.service || echo none)"
    for unit in sddm NetworkManager bluetooth; do
        echo "$unit $(systemctl is-enabled "$unit.service" 2>/dev/null || true)"
    done
    echo "ydotool(user) $(systemctl --user is-enabled ydotool.service 2>/dev/null || true)"
} | sudo tee "$backup/service-state.txt" >/dev/null
# Switching display managers takes effect at the next boot.
sudo systemctl enable --force sddm.service
sudo systemctl set-default graphical.target
systemctl --user daemon-reload
systemctl --user enable ydotool.service
# Preserve existing network management on installed desktops.
if ! systemctl is-enabled --quiet iwd.service && ! systemctl is-enabled --quiet systemd-networkd.service; then
    sudo systemctl enable NetworkManager.service
fi
sudo systemctl enable bluetooth.service
