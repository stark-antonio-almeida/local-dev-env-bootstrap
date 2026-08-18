#!/usr/bin/env bash

is_installed() {
  # Skip if installed
  cargo install --list | grep -q "^$package " && return
}

install() {
  local packages=("$@")

  cargo install "${packages[@]}"
}

validate() {
  local command="$1"

  eval "$command"
}
