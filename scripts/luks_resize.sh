#!/bin/bash
set -e

# Variables explicitly for clarity
NEW_PART="/dev/nvme0n1p8"
CRYPT_NAME="nvme0n1p8_crypt"
VG_NAME="VG0"
LV_PATH="/dev/VG0/LG0"

# --- Step 0: Fix ownership explicitly
sudo chown root:root /etc/sudoers.d
sudo find /etc/sudoers.d -type f -exec chown root:root {} \;

# --- Step 1 (critical): explicitly retrieve UUID of New LUKS Partition ---
NEW_PART_UUID=$(blkid -s UUID -o value "$NEW_PART")
if [ -z "$NEW_PART_UUID" ]; then
  echo "FAILED! explicitly failed to detect UUID for $NEW_PART."
  exit 1
fi
echo "[INFO] Detected UUID explicitly clearly as: $NEW_PART_UUID"

# --- Step 2 (critical!): explicitly update /etc/crypttab ---
CRYPTTAB_LINE="$CRYPT_NAME UUID=$NEW_PART_UUID none luks"

# Explicitly add entry if not present already explicitly clearly
if ! grep -q "^$CRYPT_NAME" /etc/crypttab; then
  echo "[INFO] Adding new crypttab line explicitly: $CRYPTTAB_LINE"
  echo "$CRYPTTAB_LINE" | sudo tee -a /etc/crypttab
else
  echo "[INFO] crypttab entry for $CRYPT_NAME already explicitly present clearly."
fi

# --- Step 3 (important after crypttab update): explicitly update-initramfs ---
sudo update-initramfs -u -k all

# --- Step 4: explicitly resize the PV explicitly ---
sudo pvresize "/dev/mapper/$CRYPT_NAME"

# --- Step 5: explicitly extend the logical volume explicitly ---
sudo lvextend -l +100%FREE "$LV_PATH"

# --- Step 6: explicitly resize btrfs explicitly ---
sudo btrfs filesystem resize max /

# --- Final verification explicitly ---
echo "[SUCCESS] Resize explicitly completed clearly. Explicit current system state:"
df -h /
sudo pvs
sudo vgs
sudo lvs $LV_PATH
sudo btrfs filesystem usage /
