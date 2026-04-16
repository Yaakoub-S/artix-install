#!/bin/sh

error_msg() {
  printf '[ERROR] %s' "$1"
}

error_out() {
  error_msg "$1"
  exit 1
}

# Parsing drive name
DRIVE=$1
[ -z "$DRIVE" ] && error_out "No device specified. Usage: $0 /dev/sda"
[ ! -b "$DRIVE" ] && error_out "$DRIVE is not a block device"
[ "$(lsblk -no TYPE "$DRIVE" | head -n1)" != "disk" ] && error_out "$DRIVE is a partition, provide the parent disk"

# Partitioning
printf '--- Partitioning ---\n'
wipefs -a "$DRIVE"
printf "label: gpt\n, 1G, L, *\n, , L\n" | sfdisk --force "$DRIVE"
partprobe "$DRIVE"
sleep 1

PART_EFI="/dev/$(lsblk -nlo NAME "$DRIVE" | sed -n '2p')"
PART_ROOT="/dev/$(lsblk -nlo NAME "$DRIVE" | sed -n '3p')"

# Encrypting the root partition
printf '--- Encrypting the root partition ---\n'

cryptsetup luksFormat "$PART_ROOT"
cryptsetup luksOpen "$PART_ROOT" cryptroot

mkfs.btrfs /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

printf '--- Creating subvolumes ---\n'

btrfs subvolumes create /mnt/@
btrfs subvolumes create /mnt/@home
btrfs subvolumes create /mnt/@log
btrfs subvolumes create /mnt/@pkg
btrfs subvolumes create /mnt/@swap
btrfs subvolumes create /mnt/@snapshots
umount /mnt

printf '--- Mounting subvolumes ---\n'

mkdir -p /mnt/home /mnt/var/log /mnt/var/cache/pacman/pkg /mnt/swap /mnt/.snapshots /mnt/efi
mount -o noatime,compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o noatime,compress=zstd,subvol=@log /dev/mapper/cryptroot /mnt/var/log
mount -o noatime,compress=zstd,subvol=@pkg /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount -o noatime,compress=zstd,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o noatime,nocompress,subvol=@swap /dev/mapper/cryptroot /mnt/swap

printf '--- Creating swapfile ---\n'

TOTAL_RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
btrfs filesystem mkswapfile --size "${TOTAL_RAM_MB}M" --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

printf '--- Formatting efi partition ---\n'

mkfs.fat -F32 "$PART_EFI"
mount "$PART_EFI" /mnt/efi

fstabgen -U /mnt >>/mnt/etc/fstab
