#!/usr/bin/env bash

is_installed() {
  # Skip if installed
  snap list "$package" >/dev/null 2>&1 && return
}

install() {
  local package="$1"
  shift

  sudo snap install "$package" "$@"
}

validate() {
  local command="$1"

  eval "$command"
}
