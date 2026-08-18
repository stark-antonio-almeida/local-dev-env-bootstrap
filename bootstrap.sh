#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=false
RECIPE_FILE="recipes/packages.json"

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

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

  jq -r '.[]' <<<"$json" | while read -r command; do

    echo "    $label: $command"
    if $DRY_RUN; then
      echo "skip"
    else
      run_command "$command"
    fi

  done
}

jq -c 'to_entries[]' "$RECIPE_FILE" | while read -r entry; do

  name=$(jq -r '.key' <<<"$entry")

  recipe=$(jq -c '.value.ubuntu' <<<"$entry")

  [[ "$recipe" == "null" ]] && continue

  echo "Cook: [$name]"

  manager=$(jq -r '.manager' <<<"$recipe")

  echo "    pantry: $manager"

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

  run_commands "season" "$(jq -c '.post // null' <<<"$recipe")"

  validations=$(jq -c '.validation // null' <<<"$recipe")

  if [[ "$validations" != "null" ]]; then

    jq -r '.[]' <<<"$validations" | while read -r command; do

      echo "    taste: $command"
      if $DRY_RUN; then
        echo "skip"
      else
        run_command "$command"
      fi

    done

  fi

  echo

done
