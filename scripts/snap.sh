#!/usr/bin/env bash

install() {
  local package="$1"

  shift

  sudo snap install "$package" "$@"
}

validate() {
  local command="$1"

  eval "$command"
}
