#!/bin/env bash

error_msg() {
  printf '[ERROR] %s' "$1"
}

error_out() {
  error_msg "$1"
  exit 1
}

EFI_MNTDIR=/mnt/efi
ROOT_MNTDIR=/mnt

# 1. Parsing drive name
drive=$1
name=${1##*/}

[[ -z "$drive" || ! -e "/sys/block/$name" ]] && error_out "'$1' is not a valid drive."

# 2. Asking permission before nuking everything
read -p "Do you want to wipe '$drive'? [y/N] " res
[[ $res != 'y' ]] && exit 1

# 3. Partitioning
echo -e "label: gpt\n,1G,U\n," | sfdisk -fq --wipe always --wipe-partitions always "$drive" &>/dev/null
(($? != 0)) && error_out "failed creating the necessary partitions."

# 4. Get partitions
mapfile -ts 1 partitions < <(sfdisk "$drive" -lqo Device)
efi_part="${partitions[0]}"
root_part="${partitions[1]}"

# 5. Format partitions
# 5.1 Format the root partition
# TODO
# 5.2 Format the efi partition
mkdir -p "$EFI_MNTDIR"
mkfs.fat -F 32 "$efi_part"
mount "$efi_part" "$EFI_MNTDIR"
