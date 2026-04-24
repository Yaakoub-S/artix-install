#!/bin/env bash

error_msg() {
  printf '[ERROR] %s' "$1"
}

error_out() {
  error_msg "$1"
  exit 1
}

# 1. Parsing drive name
drive=$1
[[ ! -e "/sys/block/$drive" ]] && error_out "'$1' is not a valid drive."

# 2. Asking Permission before nuking everything
read -p "Do you want to wipe '$drive'? [y/N] " res
[[ $res != 'y' ]] && exit 1

# 3. Partitioning
wipefs -afq "$drive" || error_out "wiping fs signatures failed."
echo -e "label: gpt\n,1G,U\n," | sfdisk "$drive"
(($? != 0)) && error_out "failed creating the necessary partitions."
