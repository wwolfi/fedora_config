## this script is a collection of all the commands to execute after a btrfs fedora installation following the sysguide installation guide for fedora 42

sudo grub2-editenv - unset menu_auto_hide
sudo dnf update -y
sudo dnf install snapper libdnf5-plugin-actions btrfs-assistant inotify-tools git make
sudo bash -c "cat > /etc/dnf/libdnf5-plugins/actions.d/snapper.actions" <<'EOF'
# Get snapshot description
pre_transaction::::/usr/bin/sh -c echo\ "tmp.cmd=$(ps\ -o\ command\ --no-headers\ -p\ '${pid}')"

# Creates pre snapshot before the transaction and stores the snapshot number in the "tmp.snapper_pre_number"  variable.
pre_transaction::::/usr/bin/sh -c echo\ "tmp.snapper_pre_number=$(snapper\ create\ -t\ pre\ -c\ number\ -p\ -d\ '${tmp.cmd}')"

# If the variable "tmp.snapper_pre_number" exists, it creates post snapshot after the transaction and removes the variable "tmp.snapper_pre_number".
post_transaction::::/usr/bin/sh -c [\ -n\ "${tmp.snapper_pre_number}"\ ]\ &&\ snapper\ create\ -t\ post\ --pre-number\ "${tmp.snapper_pre_number}"\ -c\ number\ -d\ "${tmp.cmd}"\ ;\ echo\ tmp.snapper_pre_number\ ;\ echo\ tmp.cmd
EOF
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo restorecon -RFv /.snapshots
sudo restorecon -RFv /home/.snapshots
sudo snapper -c root set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home set-config ALLOW_USERS=$USER SYNC_ACL=yes
echo 'PRUNENAMES = ".snapshots"' | sudo tee -a /etc/updatedb.conf

sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer


mkdir -p ~Documents/prog/
cd ~Documents/prog/
git clone https://github.com/Antynea/grub-btrfs
cd grub-btrfs
sed -i.bkp \
  -e '/^#GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=/a \
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rd.live.overlay.overlayfs=1"' \
  -e '/^#GRUB_BTRFS_GRUB_DIRNAME=/a \
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' \
  -e '/^#GRUB_BTRFS_MKCONFIG=/a \
GRUB_BTRFS_MKCONFIG=/usr/bin/grub2-mkconfig' \
  -e '/^#GRUB_BTRFS_SCRIPT_CHECK=/a \
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' \
  config
  
 sudo make install
 
 sudo systemctl enable --now grub-btrfsd.service
 
sudo -i
LUKS_UUID="$(grub2-probe --target=cryptodisk_uuid /)" ; echo $LUKS_UUID
mkdir -v /etc/cryptsetup-keys.d
dd if=/dev/random of=/etc/cryptsetup-keys.d/luks-${LUKS_UUID}.key bs=512 count=8
chmod -c 0400 /etc/cryptsetup-keys.d/luks-${LUKS_UUID}.key
cryptsetup luksAddKey --pbkdf pbkdf2 --pbkdf-force-iterations 500000 /dev/disk/by-uuid/${LUKS_UUID} /etc/cryptsetup-keys.d/luks-${LUKS_UUID}.key
echo "install_items+=\" /etc/cryptsetup-keys.d/luks-${LUKS_UUID}.key \"" \ > /etc/dracut.conf.d/cryptodisk.conf
dracut -vf
exit

     
curl -O https://app.eduvpn.org/linux/v4/rpm/app+linux@eduvpn.org.asc
sudo rpm --import app+linux@eduvpn.org.asc
cat << 'EOF' | sudo tee /etc/yum.repos.d/python-eduvpn-client_v4.repo
[python-eduvpn-client_v4]
name=eduVPN for Linux 4.x (Fedora $releasever)
baseurl=https://app.eduvpn.org/linux/v4/rpm/fedora-$releasever-$basearch
gpgcheck=1
EOF
sudo dnf install eduvpn-client -y

sudo wget -qO /etc/yum.repos.d/softmaker.repo https://shop.softmaker.com/repo/softmaker.repo
sudo -E dnf upgrade
sudo -E dnf install softmaker-office-2021 -y

wget $(curl -s https://api.github.com/repos/ankitects/anki/releases/latest | grep 'browser_download_url.*linux' | grep -o 'https://[^"]*' | head -n 1)
# Find the latest Anki Linux download file
LATEST_ANKI_FILE=$(ls -1t anki-*-linux-qt6.tar.zst | head -n 1)

if [ -z "$LATEST_ANKI_FILE" ]; then
    echo "No Anki tarball found in Downloads directory."
    exit 1
fi

# Extract the tarball
tar xaf "$LATEST_ANKI_FILE"

# Change into the extracted directory
EXTRACTED_DIR=$(basename "$LATEST_ANKI_FILE" .tar.zst)
cd "$EXTRACTED_DIR" || { echo "Failed to change directory."; exit 1; }

# Run the installation script
sudo ./install.sh

echo "Anki installation complete."

sudo dnf install dnf-plugins-core -y
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo dnf install brave-browser -y

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
sudo dnf install code -y

wget "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d' ' -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm"
sudo dnf install -y ./protonvpn-stable-release-1.0.3-1.noarch.rpm && sudo dnf check-update --refresh 
sudo dnf install -y proton-vpn-gnome-desktop 


sudo dnf install -y thunderbird keepassxc syncthing okular gimp texstudio texlive-scheme-full htop meld vlc ImageMagick chromium terminator tlp tlp-rdw inkscape wireguard-tools lm_sensors remmina ansible gnome-tweaks fish lshw dmidecode gparted

sudo dnf remove tuned tuned-ppd -y
sudo systemctl enable tlp.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

flatpak install flathub md.obsidian.Obsidian
flatpak install flathub org.gnome.Extensions

sudo dnf copr enable cimbali/pympress -y
sudo dnf install python3-pympress

sudo dnf copr enable rowanfr/fw-ectool -y
sudo dnf install fw-ectool -y

wget https://raw.githubusercontent.com/wwolfi/fedora_config/refs/heads/main/ectool-battery-charge-limit-service-creation.sh
sudo ./ectool-battery-charge-limit-service-creation.sh

wget https://raw.githubusercontent.com/wwolfi/fedora_config/refs/heads/main/luks-grub-update-service-creation.sh
sudo ./luks-grub-update-service-creation.sh

sudo chsh -s $(which fish)
