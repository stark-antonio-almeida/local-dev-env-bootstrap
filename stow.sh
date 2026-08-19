#!/usr/bin/env bash

set -euo pipefail

TARGET="${HOME}"
DRY_RUN=false
SEED=false

seed_package() {
  local package="$1"

  while IFS= read -r source_file; do
    local relative="${source_file#./$package/}"
    local target="$TARGET/$relative"

    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "Seeding: removing $target"
      rm -f "$target"
    fi

  done < <(find "./$package" -type f)
}
for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=true
    ;;
  --target=*)
    TARGET="${arg#*=}"
    ;;
  --seed)
    SEED=true
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

  if $SEED; then
    while IFS= read -r relative; do
      target_file="$TARGET/$relative"

      if [[ -f "$target_file" && ! -L "$target_file" ]]; then
        echo "Source : $package/$relative"
        echo "Target : $target_file"
        if ! $DRY_RUN; then
          echo "  Seed: removing $target_file"
          rm -f "$target_file"
        fi
      fi

    done < <(
      cd "$package" &&
        find . -type f
    )
  fi

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
