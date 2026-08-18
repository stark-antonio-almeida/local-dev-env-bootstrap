#!/usr/bin/env bash

set -euo pipefail

cd stow

for package in *; do
  echo "Stowing: $package"
  stow -t "$HOME" "$package"
done
