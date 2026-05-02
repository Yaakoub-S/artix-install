#!/bin/env bash

error_msg() {
  printf '[ERROR] %s' "$1"
}

error_out() {
  error_msg "$1"
  exit 1
}

get_ram_gb() {
  local ram_kb
  ram_kb=$(grep -Po '(?<=MemTotal:)\s*\K\d+' /proc/meminfo)

  [[ -z "$ram_kb" ]] && return 1
  echo $((ram_kb / 1024 / 1024))
  return 0
}

is_laptop() {
  grep -qE "^(8|9|10|11|14)$" /sys/class/dmi/id/chassis_type 2>/dev/null
}
