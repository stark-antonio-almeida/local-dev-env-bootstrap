#!/usr/bin/env bash

install() {
  local packages=("$@")

  # Skip if installed
  dpkg -s "$package" >/dev/null 2>&1 && return
  sudo apt install -y "${packages[@]}"
}

validate() {
  local command="$1"

  eval "$command"
}
