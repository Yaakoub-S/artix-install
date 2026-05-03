#!/bin/env bash

if [[ -z $LIB_PATH ]]; then
  printf "[ERROR] this module must be run by install.sh.\n"
  exit 1
fi
. "$LIB_PATH"

drive=$1
name=${1##*/}

[[ -z "$drive" || ! -e "/sys/block/$name" ]] && error_out "'$1' is not a valid drive."

# Preparing the drive for partitioning
swapoff -a &>/dev/null
umount -R /mnt &>/dev/null

if [[ -b "/dev/mapper/cryptroot" ]]; then
  sync
  fuser -kvm /dev/mapper/cryptroot &>/dev/null
  sleep 2
  cryptsetup close cryptroot &>/dev/null
fi

read -p "Do you want to wipe '$drive'? [y/N] " res
[[ $res ~= 'y|Y' ]] && exit 1

# Partitioning
echo -e "label: gpt\n,1G,U\n," | sfdisk -fq --wipe always --wipe-partitions always "$drive" || error_out "failed creating the necessary partitions."
