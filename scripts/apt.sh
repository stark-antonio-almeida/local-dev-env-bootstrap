#!/usr/bin/env bash

is_installed() {
  # Skip if installed
  dpkg -s "$package" >/dev/null 2>&1 && return
}

install() {
  local packages=("$@")

  sudo apt install -y "${packages[@]}"
}

validate() {
  local command="$1"

  eval "$command"
}
