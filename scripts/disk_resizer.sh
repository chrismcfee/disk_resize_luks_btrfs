#!/bin/bash
set -e
TARGET_DISK="/dev/nvme0n1"
NEW_PART="/dev/nvme0n1p8"
VG_NAME="VG0"
CRYPT_NAME="nvme0n1p8_crypt"

echo "[INFO] Current partition table and free space:"
parted -s "$TARGET_DISK" print free

# Auto-detect FREE start
START_VALUE=$(parted -ms "$TARGET_DISK" print free | grep free | tail -1 | cut -d: -f2)

echo "[INFO] Creating new partition from $START_VALUE to 100%"
parted -s -a optimal "$TARGET_DISK" mkpart primary "$START_VALUE" 100%
partprobe "$TARGET_DISK"
sleep 5  # Wait briefly for partition table to refresh

echo "[INFO] Setting up LUKS encryption clearly on $NEW_PART"
echo -n "{{ luks_passphrase }}" | cryptsetup luksFormat "$NEW_PART" -
echo -n "{{ luks_passphrase }}" | cryptsetup open "$NEW_PART" "$CRYPT_NAME" -

echo "[INFO] Creating PV explicitly clearly on encrypted partition"
pvcreate "/dev/mapper/$CRYPT_NAME"
vgextend "$VG_NAME" "/dev/mapper/$CRYPT_NAME"

echo "[SUCCESS] Partition added, encrypted, and PV/VG resized explicitly clearly."
