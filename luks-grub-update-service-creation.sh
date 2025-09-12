#!/bin/bash

# Create the service file
cat << 'EOF' > /etc/systemd/system/pre-shutdown-luks-grub.service
[Unit]
Description=Pre-shutdown LUKS/GRUB configuration update
DefaultDependencies=false
Before=shutdown.target reboot.target halt.target
Conflicts=shutdown.target reboot.target halt.target
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/true
ExecStop=/usr/local/bin/luks-grub-update.sh
TimeoutStopSec=30
KillMode=none

[Install]
WantedBy=multi-user.target
EOF

# Create the script that will be executed
cat << 'EOF' > /usr/local/bin/luks-grub-update.sh
#!/bin/bash

# Log all output to systemd journal and syslog
exec 1> >(logger -s -t luks-grub-update)
exec 2>&1

echo "Starting LUKS/GRUB configuration update..."

# Get LUKS device
LUKS_DEVICE="$(sudo cryptsetup status \
    $(sudo grub2-probe --target=device /) \
    | grep 'device:' | awk '{print $2}')"
echo "LUKS_DEVICE: $LUKS_DEVICE"

# Get LUKS UUID
LUKS_UUID="$(sudo cryptsetup luksUUID ${LUKS_DEVICE})"
echo "LUKS_UUID: $LUKS_UUID"

# Get default snapshot
DEF_SNAP="$(sudo btrfs subvolume get-default / | awk '{print $NF}')/"
echo "DEF_SNAP: $DEF_SNAP"

# Update GRUB configuration
echo "Updating GRUB configuration..."
sudo sed -i.bkp \
    -e '1i set btrfs_relative_path="yes"' \
    -e "1i cryptomount -u ${LUKS_UUID//-/}" \
    -e "s|$DEF_SNAP||g" \
    /boot/efi/EFI/fedora/grub.cfg

echo "LUKS/GRUB configuration update completed successfully"
EOF

# Make the script executable
chmod +x /usr/local/bin/luks-grub-update.sh

# Enable and start the service
systemctl daemon-reload
systemctl enable pre-shutdown-luks-grub.service
systemctl start pre-shutdown-luks-grub.service

echo "Service created and enabled successfully!"
echo ""
echo "To check service status:"
echo "systemctl status pre-shutdown-luks-grub.service"
echo ""
echo "To view logs:"
echo "journalctl -u pre-shutdown-luks-grub.service"
echo ""
echo "To test the script manually:"
echo "/usr/local/bin/luks-grub-update.sh"
