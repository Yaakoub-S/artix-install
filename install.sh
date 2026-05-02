#!/bin/env bash

# Sourcing lib.sh
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if [[ ! -f "$SCRIPT_DIR/lib.sh" ]]; then
  printf '[ERROR] sourcing lib.sh failed.\n'
  exit 1
fi
export LIB_PATH="$SCRIPT_DIR/lib.sh"
. "$LIB_PATH"

# Functions
usage() {
  printf "Usage: %s -d <drive_name>\n\n" "$0"
  printf "Options:\n"
  printf " -d\n\t specify the target drive for installation (e.g., /dev/sdb)\n"
  printf " -h\n\t display this help and exit\n\n"
}

# Parsing arguments
drive=""
while getopts ":d:h" opt; do
  case $opt in
  d) drive="$OPTARG" ;;
  h) usage ;;
  \?) usage_error "-$OPTARG is not a valid option." ;;
  :) usage_error "missing argument for -$OPTARG." ;;
  esac
done

[[ -z $drive ]] && usage_error "please provide a drive name to install to."

# Calling modules
$SCRIPT_DIR/modules/01_partition.sh "$drive" || exit 1
