#!/bin/bash
set -e

MNT=/mnt
ROOT_DEV=/dev/dm-0
EFI_PART=/dev/nvme0n1p1

echo "[*] Unmounting any existing mounts..."
sudo umount -R $MNT 2>/dev/null || true

echo "[*] Mounting Fedora 42 snapshot as root..."
sudo mount -o rw,subvol=snapshots/391/snapshot $ROOT_DEV $MNT

echo "[*] Creating mount points..."
sudo mkdir -p $MNT/{home,var,opt,tmp,usr/local,snapshots,boot/efi,dev,proc,sys,run,etc}

echo "[*] Mounting Btrfs subvolumes..."
# Mount subvolumes that exist
for sub in home var opt tmp usr-local snapshots; do
    # Check if subvolume exists (using exact match)
    if sudo btrfs subvolume list $MNT | grep -q " path $sub$"; then
        echo "[*] Mounting subvolume: $sub"
        sudo mount -o rw,subvol=$sub $ROOT_DEV $MNT/$sub
    else
        echo "[*] Subvolume $sub not found, skipping"
    fi
done

# Handle usr-local -> usr/local mapping
if sudo btrfs subvolume list $MNT | grep -q " path usr-local$"; then
    echo "[*] Mounting usr-local to usr/local"
    sudo mkdir -p $MNT/usr/local
    sudo mount -o rw,subvol=usr-local $ROOT_DEV $MNT/usr/local
fi

BOOT_PART=/dev/nvme0n1p3
sudo mkdir -p $MNT/boot
sudo mount $BOOT_PART $MNT/boot


echo "[*] Mounting EFI partition..."
sudo mount $EFI_PART $MNT/boot/efi

echo "[*] Binding system directories..."
for dir in dev proc sys run; do
    sudo mount --bind /$dir $MNT/$dir
done

echo "[*] Setting up resolv.conf..."
# Copy resolv.conf instead of bind mounting if target doesn't exist
if [ -f /etc/resolv.conf ]; then
    sudo cp /etc/resolv.conf $MNT/etc/resolv.conf
fi

echo "[*] Chroot environment ready!"
echo "[*] To enter chroot: sudo chroot $MNT /bin/bash"
echo "[*] To cleanup: sudo umount -R $MNT"

# Optional: automatically enter chroot
read -p "Enter chroot now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo chroot $MNT /bin/bash
fi
