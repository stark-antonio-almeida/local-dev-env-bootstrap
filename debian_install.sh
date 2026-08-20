#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/dataaal/local-dev-env-bootstrap.git"
INSTALL_DIR="$HOME/.local-dev-env-bootstrap"

RUN_BOOTSTRAP=true
RUN_STOW=true

BOOTSTRAP_ARGS=()

DRY_RUN=false
PLATFORM=""

BOOTSTRAP_ARGS=()

for arg in "$@"; do
  case "$arg" in
  --repo=*)
    REPO_URL="${arg#*=}"
    ;;

  --install-dir=*)
    INSTALL_DIR="${arg#*=}"
    ;;

  --platform=*)
    PLATFORM="${arg#*=}"
    ;;

  --dry-run)
    DRY_RUN=true
    ;;

  --no-bootstrap)
    RUN_BOOTSTRAP=false
    ;;

  --no-stow)
    RUN_STOW=false
    ;;

  *)
    BOOTSTRAP_ARGS+=("$arg")
    ;;
  esac
done

bootstrap_args=("${BOOTSTRAP_ARGS[@]}")

if [[ -n "$PLATFORM" ]]; then
  bootstrap_args+=("--platform=$PLATFORM")
fi

if $DRY_RUN; then
  bootstrap_args+=("--dry-run")
fi

ensure_command() {
  local command="$1"
  local package="$2"

  if command -v "$command" >/dev/null 2>&1; then
    return
  fi

  echo "Installing prerequisite: $package"

  sudo apt update
  sudo apt install -y "$package"
}

ensure_command git git
ensure_command jq jq

mkdir -p "$(dirname "$INSTALL_DIR")"

if [[ ! -d "$INSTALL_DIR/.git" ]]; then
  echo "Cloning:"
  echo "  Repo : $REPO_URL"
  echo "  Into : $INSTALL_DIR"

  git clone "$REPO_URL" "$INSTALL_DIR"
else
  echo "Updating:"
  echo "  Repo : $INSTALL_DIR"

  git -C "$INSTALL_DIR" pull --ff-only
fi

if $RUN_BOOTSTRAP; then
  echo
  echo "Running bootstrap..."

  "$INSTALL_DIR/bootstrap.sh" "${bootstrap_args[@]}"
fi

if $RUN_STOW; then
  echo
  echo "Running stow..."

  stow_args=(--seed)

  if $DRY_RUN; then
    stow_args+=(--dry-run)
  fi

  "$INSTALL_DIR/stow.sh" "${stow_args[@]}"
fi

echo
echo "Done"
