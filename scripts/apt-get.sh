#!/usr/bin/env bash

install() {
  local packages=("$@")

  sudo apt-get install -y "${packages[@]}"
}

validate() {
  local command="$1"

  eval "$command"
}
