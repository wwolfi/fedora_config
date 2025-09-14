#!/bin/bash

# Fedora System Configuration with Ansible
# This script installs Ansible and runs the configuration playbook

set -e

echo "============================================================================"
echo "Fedora System Configuration Setup"
echo "============================================================================"

# Check if running as regular user
if [[ $EUID -eq 0 ]]; then
   echo "Error: This script should not be run as root!" 
   echo "Run as a regular user - Ansible will use sudo when needed."
   exit 1
fi

# Check if we're on Fedora
if ! grep -q "Fedora" /etc/os-release; then
    echo "Warning: This script is designed for Fedora Linux"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Step 1: Installing Ansible..."
if ! command -v ansible-playbook &> /dev/null; then
    sudo dnf install -y ansible
    echo "Ansible installed successfully!"
else
    echo "Ansible is already installed."
fi

echo ""
echo "Step 2: Installing additional required packages..."
sudo dnf install -y python3-pip python3-pexpect

echo ""
echo "Step 3: Creating inventory file..."
cat > inventory.ini << 'EOF'
[local]
localhost ansible_connection=local

[local:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

echo ""
echo "Step 4: Checking Ansible installation..."
ansible --version
echo ""

# Check for LUKS encryption
if cryptsetup isLuks $(df / | tail -1 | cut -d' ' -f1 | sed 's/[0-9]*$//'); then
    echo "LUKS encryption detected."
    read -s -p "Enter your LUKS passphrase (for key addition): " LUKS_PASS
    echo ""
    export LUKS_PASSPHRASE="$LUKS_PASS"
fi

echo "Step 5: Running Ansible playbook..."
echo "This will configure your Fedora system with all the specified software and settings."
echo "The process may take 30-60 minutes depending on your internet connection."
echo ""

read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

echo ""
echo "Starting configuration..."
ansible-playbook -i inventory.ini fedora-config-program-installation.yml -K \
    ${LUKS_PASSPHRASE:+-e "luks_passphrase=$LUKS_PASSPHRASE"} \
    -v

echo ""
echo "============================================================================"
echo "Configuration completed!"
echo ""
echo "Next steps:"
echo "1. Reboot your system: sudo reboot"
echo "2. Check that GRUB shows snapshot entries"
echo "3. Configure individual applications as needed"
echo ""
echo "Services that were configured:"
echo "- Snapper automatic snapshots"
echo "- TLP power management"
echo "- Battery charge limiting (if Framework laptop)"
echo "- LUKS key management"
echo ""
echo "============================================================================"
