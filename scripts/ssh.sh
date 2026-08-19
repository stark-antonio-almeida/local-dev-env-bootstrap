#!/usr/bin/env bash

install() {
  local key_name="$1"
  shift

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  ssh-keygen \
    "$@" \
    -f "$HOME/.ssh/$key_name" \
    -N "" \
    -C "$(whoami)@$(hostname)"
}

validate() {
  local key_name="$1"

  [[ -f "$HOME/.ssh/$key_name.pub" ]]
}
