#!/bin/bash

# Create the service file
cat << 'EOF' > /etc/systemd/system/ectool-charge-limit.service
[Unit]
Description=Set EC firmware charge limit to 70%
After=multi-user.target
Wants=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-charge-limit.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create the script that will be executed
cat << 'EOF' > /usr/local/bin/set-charge-limit.sh
#!/bin/bash

# Log all output to systemd journal and syslog
exec 1> >(logger -s -t set-charge-limit)
exec 2>&1

echo "Starting EC firmware charge limit configuration..."

# Check if ectool exists
if ! command -v /usr/bin/ectool &> /dev/null; then
    echo "ERROR: /usr/bin/ectool not found. Please install the ec-utils package or ensure ectool is available."
    exit 1
fi

# Set the charge limit to 70%
echo "Setting firmware charge limit to 70%..."
if /usr/bin/ectool fwchargelimit 70; then
    echo "Successfully set firmware charge limit to 70%"
    
    # Verify the setting (if ectool supports reading the current limit)
    echo "Attempting to verify current charge limit setting..."
    if /usr/bin/ectool fwchargelimit 2>/dev/null; then
        echo "Charge limit verification completed"
    else
        echo "Note: Unable to verify charge limit (ectool may not support reading current value)"
    fi
else
    echo "ERROR: Failed to set firmware charge limit"
    exit 1
fi

echo "EC firmware charge limit configuration completed successfully"
EOF

# Make the script executable
chmod +x /usr/local/bin/set-charge-limit.sh

# Enable and start the service
systemctl daemon-reload
systemctl enable ectool-charge-limit.service

# Test the service immediately
echo "Testing the service..."
systemctl start ectool-charge-limit.service

echo ""
echo "Service created and enabled successfully!"
echo ""
echo "Service will run automatically on every system startup."
echo ""
echo "To check service status:"
echo "systemctl status ectool-charge-limit.service"
echo ""
echo "To view logs:"
echo "journalctl -u ectool-charge-limit.service"
echo ""
echo "To test the script manually:"
echo "/usr/local/bin/set-charge-limit.sh"
echo ""
echo "To disable the service (if needed):"
echo "systemctl disable ectool-charge-limit.service"
echo ""
echo "Current service status:"
systemctl status ectool-charge-limit.service --no-pager
