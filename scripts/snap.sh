#!/usr/bin/env bash

install() {
  local package="$1"
  shift

  # Skip if installed
  snap list "$package" >/dev/null 2>&1 && return
  sudo snap install "$package" "$@"
}

validate() {
  local command="$1"

  eval "$command"
}
