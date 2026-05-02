#!/bin/env bash

[[ -z $LIB_PATH ]] && error_out "this module must be run by install.sh"
. "$LIB_PATH"

drive=$1
name=${1##*/}

[[ -z "$drive" || ! -e "/sys/block/$name" ]] && error_out "'$1' is not a valid drive."

read -p "Do you want to wipe '$drive'? [y/N] " res
[[ $res != 'y' ]] && exit 1

echo -e "label: gpt\n,1G,U\n," | sfdisk -fq --wipe always --wipe-partitions always "$drive"
(($? != 0)) && error_out "failed creating the necessary partitions."
