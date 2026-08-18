#!/usr/bin/env bash

install() {
  local packages=("$@")

  # Skip if installed
  cargo install --list | grep -q "^$package " && return
  cargo install "${packages[@]}"
}

validate() {
  local command="$1"

  eval "$command"
}
