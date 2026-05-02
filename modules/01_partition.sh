#!/bin/env bash

if [[ ! -z "$LIB_PATH" || ! -f "$LIB_PATH" ]]; then
  printf "[ERROR] Failed sourcing lib.sh\n"
  exit 1
fi

drive=$1
name=${1##*/}

[[ -z "$drive" || ! -e "/sys/block/$name" ]] && error_out "'$1' is not a valid drive."

read -p "Do you want to wipe '$drive'? [y/N] " res
[[ $res != 'y' ]] && exit 1

echo -e "label: gpt\n,1G,U\n," | sfdisk -fq --wipe always --wipe-partitions always "$drive" &>/dev/null
(($? != 0)) && error_out "failed creating the necessary partitions."
