#!/bin/env bash

MAPPER_DEV=/dev/mapper/cryptroot
EFI_MNTP=/mnt/efi
MNTP=/mnt

if [[ -z $LIB_PATH ]]; then
  printf "[ERROR] this module must be run by install.sh.\n"
  exit 1
fi
. "$LIB_PATH"

drive=$1
name=${1##*/}

[[ -z "$drive" || ! -e "/sys/block/$name" ]] && error_out "'$1' is not a valid drive."

# Fetching partitions
mapfile -ts 1 partitions < <(sfdisk "$drive" -lqo Device)
efi_part="${partitions[0]}"
root_part="${partitions[1]}"

# Format root partition
cryptsetup luksFormat "$root_part" || error_out "cryptsetup failed."
cryptsetup luksOpen "$root_part" cryptroot || error_out "failed opening root partition."
mkfs.btrfs "$MAPPER_DEV" || error_out "failed creating the btrfs filesystem."
mount "$MAPPER_DEV" "$MNTP" || error_out "failed mounting mapper partition."

subvols=("@" "@home" "@log" "@pkg" "@.snapshots" "@.swap")
paths=("" "/home" "/var/log" "/var/cache/pacman/pkg" "/.snapshots" "/.swap")
mount "$MAPPER_DEV" "$MNTP"
for sub in "${subvols[@]}"; do
  btrfs subvolume create "$MNTP/$sub" || error_out "creating '$sub' subvolume failed."
done
umount "$MNTP"

for i in "${!subvols[@]}"; do
  sub="${subvols[$i]}"
  path="${paths[$i]}"
  target="$MNTP$path"

  opts="$mount_options"
  [[ "$sub" == "@.swap" ]] && opts="${mount_options##*,}"

  mkdir -p "$target"
  mount -o "subvol=$sub,$opts" "$MAPPER_DEV" "$target" || error_out "mounting '$sub' subvolume failed."
done

# Format the efi partition
mkdir -p "$EFI_MNTDIR"
mkfs.fat -F 32 "$efi_part"
mount "$efi_part" "$EFI_MNTDIR"
