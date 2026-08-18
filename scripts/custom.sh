#!/usr/bin/env bash

install() {
  local command="$1"

  eval "$command"
}

validate() {
  local command="$1"

  eval "$command"
}
