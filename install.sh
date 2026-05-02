#!/bin/env bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if [[ ! -f "$SCRIPT_DIR/lib.sh" ]]; then
  printf '[ERROR] sourcing lib.sh failed\n'
  exit 1
fi
export LIB_DIR="$SCRIPT_DIR/lib.sh"
. "$SCRIPT_DIR/lib.sh"
