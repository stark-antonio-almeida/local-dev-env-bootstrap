#!/usr/bin/env bash

install() {
  local packages=("$@")

  sudo apt install -y "${packages[@]}"
}

validate() {
  local command="$1"

  eval "$command"
}
