#!/bin/bash
set -e

echo "=========================================="
echo "      Starting full resize procedure"
echo "=========================================="

# --- Step 0: Fix /etc/sudoers.d Ownership ---
echo "[Step 0] Fixing /etc/sudoers.d ownership..."
sudo chown root:root /etc/sudoers.d
sudo find /etc/sudoers.d -type f -exec chown root:root {} \;
echo "Ownership for /etc/sudoers.d fixed."
echo "------------------------------------------"

# --- Step 1: Resize the LUKS Container ---
echo "[Step 1] Resizing LUKS container 'sda3_crypt' (if underlying partition size changed)..."
sudo cryptsetup resize sda3_crypt
echo "LUKS container resize complete."
echo "------------------------------------------"

# --- Step 2: Resize the LVM Physical Volume ---
echo "[Step 2] Resizing physical volume on /dev/mapper/sda3_crypt..."
sudo pvresize /dev/mapper/sda3_crypt
echo "Physical volume resize complete."
echo "------------------------------------------"

# --- Step 3: Extend the Logical Volume ---
echo "[Step 3] Extending logical volume VG0/LG0 to use available free space..."
sudo lvextend -l +100%FREE /dev/VG0/LG0
echo "Logical volume extended."
echo "------------------------------------------"

# --- Step 4: Resize the Btrfs Filesystem ---
echo "[Step 4] Resizing Btrfs filesystem on / to fill the LV..."
sudo btrfs filesystem resize max /
echo "Btrfs filesystem resize complete."
echo "------------------------------------------"

# --- Step 5: Update initramfs to persist changes (especially LUKS info) ---
echo "[Step 5] Updating initramfs to capture current configuration..."
sudo update-initramfs -u -k all
echo "initramfs update complete."
echo "------------------------------------------"

# --- (Optional) Step 6: Create a systemd service to run cryptsetup resize on boot ---
# This is useful if you find that after reboot the LUKS container does not reflect the new size.
if [ ! -f /etc/systemd/system/cryptresize.service ]; then
    echo "[Step 6] Creating a systemd service to auto-resize LUKS container on boot..."
    sudo bash -c 'cat > /etc/systemd/system/cryptresize.service <<EOF
[Unit]
Description=Resize LUKS container after boot
After=local-fs.target
Before=umount.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/cryptsetup resize sda3_crypt

[Install]
WantedBy=multi-user.target
EOF'
    sudo systemctl enable cryptresize.service
    echo "Systemd service 'cryptresize' created and enabled."
else
    echo "[Step 6] Systemd service for cryptsetup resize already exists."
fi
echo "------------------------------------------"

echo "=========================================="
echo "   Resize procedure complete!"
echo "   Please reboot to verify changes persist."
echo "=========================================="

# --- Final Verification ---
echo "Verifying current state (pre-reboot):"
echo ""
echo "1) df -h /:"
df -h /
echo ""
echo "2) LVM physical volumes (pvs):"
sudo pvs
echo ""
echo "3) LVM volume groups (vgs):"
sudo vgs
echo ""
echo "4) LVM logical volume details (lvdisplay):"
sudo lvdisplay /dev/VG0/LG0
echo ""
echo "5) Btrfs filesystem usage:"
sudo btrfs filesystem usage /
echo ""
echo "=========================================="
