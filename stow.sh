#!/usr/bin/env bash

set -euo pipefail

TARGET="${HOME}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=true
    ;;
  --target=*)
    TARGET="${arg#*=}"
    ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="${SCRIPT_DIR}/stow"

if ! command -v stow >/dev/null 2>&1; then
  echo "❌ stow is not installed" >&2
  exit 1
fi

if [[ ! -d "$STOW_DIR" ]]; then
  echo "❌ Missing stow directory: $STOW_DIR" >&2
  exit 1
fi

shopt -s nullglob

pushd "$STOW_DIR" >/dev/null

failed_packages=()

for package_path in *; do
  [[ -d "$package_path" ]] || continue
  package="$package_path"
  echo "Stowing: $package"

  if $DRY_RUN; then
    if ! stow --no --restow --target "$TARGET" "$package"; then
      failed_packages+=("$package")
    fi
  else
    if ! stow --restow --target "$TARGET" "$package"; then
      failed_packages+=("$package")
    fi
  fi
done

popd >/dev/null

if ((${#failed_packages[@]} > 0)); then
  echo "❌ Failed : ${failed_packages[*]}" >&2
  exit 1
fi
