#!/bin/env bash

MAPPER_DEV=/dev/mapper/cryptroot
EFI_MNTP=/mnt/efi
MNTP=/mnt

if [[ ! -z "$LIB_PATH" || ! -f "$LIB_PATH" ]]; then
  printf "[ERROR] Failed sourcing lib.sh\n"
  exit 1
fi

drive=$1
name=${1##*/}

[[ -z "$drive" || ! -e "/sys/block/$name" ]] && error_out "'$1' is not a valid drive."

# Fetching partitions
mapfile -ts 1 partitions < <(sfdisk "$drive" -lqo Device)
efi_part="${partitions[0]}"
root_part="${partitions[1]}"

# Format root partition
cryptsetup luksFormat "$root_part" || error_out "cryptsetup failed."
cryptsetup luksOpen "$root_part" cryproot || error_out "failed opening root partition."
mkfs.btrfs "$MAPPER_DEV" || error_out "failed creating the btrfs filesystem."
mount "$MAPPER_DEV" "$MNTP" || error_out "failed mounting mapper partition."

subvols=("@" "@home" "@log" "@pkg" "@.snapshots")
swap_subvol="@.swap"
mount_options='compress=zstd,noatime'

for sub in "${subvols[@]} $swap_subvol"; do
  btrfs subvolume create "$MNTP/$sub" &>/dev/null
  (($? != 0)) && umount "$MNTP" && error_out "subvolume creation failed."
done
umount "$MNTP"

mount -o "subvol=@,$mount_options" "$MAPPER_DEV" "$MNTP"

mkdir -p "$MNTP/home" "$MNTP/var/log" "$MNTP/var/cache/pacman/pkg" "$MNTP/.snapshots" "$MNTP/.swap"
mount -o "subvol=@home,$mount_options" "$MAPPER_DEV" "$MNTP/home"
mount -o "subvol=@log,$mount_options" "$MAPPER_DEV" "$MNTP/var/log"
mount -o "subvol=@pkg,$mount_options" "$MAPPER_DEV" "$MNTP/var/cache/pacman/pkg"
mount -o "subvol=@.snapshots,$mount_options" "$MAPPER_DEV" "$MNTP/.snapshots"
mount -o "subvol=@.swap,${mount_options##*,}" "$MAPPER_DEV" "$MNTP/.swap"

# Format the efi partition
mkdir -p "$EFI_MNTDIR"
mkfs.fat -F 32 "$efi_part"
mount "$efi_part" "$EFI_MNTDIR"
