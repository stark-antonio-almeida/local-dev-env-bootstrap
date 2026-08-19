#!/usr/bin/env bash

install() {
  local packages=("$@")

  cargo install "${packages[@]}"
}

validate() {
  local command="$1"

  eval "$command"
}
