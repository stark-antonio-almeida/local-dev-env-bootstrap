#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ Failed at line $LINENO"' ERR

DRY_RUN=false
RECIPE_FILE="recipes/packages.json"
installed_packages=()
skip_packages=()
dry_run_packages=()

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

ensure_command() {
  local command="$1"
  local package="$2"

  if command -v "$command" >/dev/null 2>&1; then
    return
  fi

  echo "Kitchen: stocking $package"

  if ! $DRY_RUN; then
    sudo apt update
    sudo apt install -y "$package"
  fi
}

ensure_command jq jq

run_command() {
  local command="$1"

  echo "    do: $command"
  if $DRY_RUN; then
    echo "skip"
  else
    eval "$command"
  fi
}

run_commands() {
  local label="$1"
  local json="$2"

  [[ "$json" == "null" ]] && return 0

  while read -r command; do

    echo "    $label: $command"

    if $DRY_RUN; then
      echo "skip"
    else
      run_command "$command"
    fi

  done < <(jq -r '.[]' <<<"$json")
}

while read -r entry; do

  name=$(jq -r '.key' <<<"$entry")

  recipe=$(jq -c '.value.ubuntu' <<<"$entry")

  [[ "$recipe" == "null" ]] && continue

  echo "Cook: [$name]"

  manager=$(jq -r '.manager' <<<"$recipe")

  echo "    pantry: $manager"

  skip_install=false
  package=""
  source "scripts/$manager.sh"

  # Run validations to check if it is installed
  validations=$(jq -c '.validation // null' <<<"$recipe")

  if [[ "$validations" != "null" ]]; then

    while read -r command; do

      if run_command "$command"; then
        echo "    stocked: $name"
        skip_packages+=("$name")
        skip_install=true
      fi

    done < <(jq -r '.[]' <<<"$validations")

  fi

  if ! $skip_install; then
    # Run pre
    run_commands "prep" "$(jq -c '.pre // null' <<<"$recipe")"

    if jq -e '.package' <<<"$recipe" >/dev/null; then

      package=$(jq -r '.package' <<<"$recipe")

      flags=$(jq -r '.flags[]?' <<<"$recipe")

      echo "    simmer: $package $flags"
      if $DRY_RUN; then
        echo "skip"
      else
        source "scripts/$manager.sh"

        install "$package" $flags
      fi
    fi

    if jq -e '.install' <<<"$recipe" >/dev/null; then

      run_commands "cook" "$(jq -c '.install' <<<"$recipe")"

    fi

    # Run post
    run_commands "season" "$(jq -c '.post // null' <<<"$recipe")"

    # Run validations
    validations=$(jq -c '.validation // null' <<<"$recipe")

    if [[ "$validations" != "null" ]]; then

      while read -r command; do

        echo "    taste: $command"

        if $DRY_RUN; then
          echo "skip"
          dry_run_packages+=("$name")
        else
          run_command "$command"
          installed_packages+=("$name")
        fi

      done < <(jq -r '.[]' <<<"$validations")

    fi
  fi

  echo

done < <(jq -c 'to_entries[]' "$RECIPE_FILE")

echo "Skip : ${skip_packages[*]}"
echo "Dry Run : ${dry_run_packages[*]}"
echo "Installed : ${installed_packages[*]}"
