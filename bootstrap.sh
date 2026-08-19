#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ Failed at line $LINENO"' ERR

DRY_RUN=false
OUTPUT_FORMAT="human"
RECIPE_FILE="recipes/packages.json"
installed_packages=()
skip_packages=()
dry_run_packages=()
failed_packages=()
events_json='[]'
started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

TARGET_PLATFORM="wsl-ubuntu"

for arg in "$@"; do
  case "$arg" in
  --dry-run)
    DRY_RUN=true
    ;;
  --platform=*)
    TARGET_PLATFORM="${arg#*=}"
    ;;
  --output=*)
    OUTPUT_FORMAT="${arg#*=}"
    ;;
  *)
    echo "❌ Unknown argument: $arg" >&2
    exit 1
    ;;
  esac
done

if [[ "$OUTPUT_FORMAT" != "human" && "$OUTPUT_FORMAT" != "json" ]]; then
  echo "❌ Unsupported output format: $OUTPUT_FORMAT (expected: human|json)" >&2
  exit 1
fi

# Decide is output needs to be captured
capture_output=false
[[ "$OUTPUT_FORMAT" == "json" ]] && capture_output=true

log() {
  local line="$1"
  if [[ "$OUTPUT_FORMAT" == "human" ]]; then
    echo "$line"
  fi
}

record_event() {
  local package="$1"
  local phase="$2"
  local action="$3"
  local status="$4"
  local command="$5"
  local output="$6"

  events_json=$(
    jq -c \
      --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
      --arg package "$package" \
      --arg phase "$phase" \
      --arg action "$action" \
      --arg status "$status" \
      --arg command "$command" \
      --arg output "$output" \
      '. + [{
        timestamp: $ts,
        package: $package,
        phase: $phase,
        action: $action,
        status: $status,
        command: $command,
        output: $output
      }]' <<<"$events_json"
  )
}

print_output_block() {
  local output="$1"
  [[ -z "$output" ]] && return 0

  if [[ "$OUTPUT_FORMAT" == "human" ]]; then
    while IFS= read -r line; do
      echo "      | $line"
    done <<<"$output"
  fi
}

run_eval_command() {
  local package="$1"
  local phase="$2"
  local action="$3"
  local command="$4"
  local quiet_success="${5:-false}"
  local output=""
  local status=0

  log "[$phase]: $command"

  if $DRY_RUN; then
    log "      -> skip (dry-run)"

    if $capture_output; then
      record_event "$package" "$phase" "$action" "dry-run" "$command" ""
    fi

    return 0
  fi

  if $capture_output; then
    local tmp
    tmp=$(mktemp)

    if eval "$command" >"$tmp" 2>&1; then
      output=$(<"$tmp")
      rm -f "$tmp"

      if [[ "$quiet_success" != "true" ]]; then
        print_output_block "$output"
      fi

      record_event "$package" "$phase" "$action" "ok" "$command" "$output"
      return 0
    else
      status=$?
      output=$(<"$tmp")
      rm -f "$tmp"

      print_output_block "$output"
      record_event "$package" "$phase" "$action" "failed" "$command" "$output"
      log "      -> failed (exit $status)"
      return "$status"
    fi
  else
    if eval "$command"; then
      return 0
    else
      status=$?
      log "      -> failed (exit $status)"
      return "$status"
    fi
  fi
}

run_validation_command() {
  local package="$1"
  local phase="$2"
  local command="$3"
  local quiet_success="${4:-false}"
  local output=""
  local status=0

  if $DRY_RUN && [[ "$phase" == "taste" ]]; then
    log "[taste  ]: $command"
    log "      -> skip (dry-run)"
    record_event "$package" "$phase" "validation" "dry-run" "$command" ""
    return 0
  fi

  if ! $DRY_RUN && [[ "$phase" == "taste" ]]; then
    log "[taste  ]: $command"
  fi

  if $DRY_RUN && [[ "$phase" == "taste" ]]; then
    return 0
  fi

  if declare -F validate >/dev/null 2>&1; then
    if output=$(validate "$command" 2>&1); then
      if [[ "$quiet_success" != "true" ]]; then
        print_output_block "$output"
      fi
      record_event "$package" "$phase" "validation" "ok" "$command" "$output"
      return 0
    else
      status=$?
    fi
  else
    if output=$(eval "$command" 2>&1); then
      if [[ "$quiet_success" != "true" ]]; then
        print_output_block "$output"
      fi
      record_event "$package" "$phase" "validation" "ok" "$command" "$output"
      return 0
    else
      status=$?
    fi
  fi

  print_output_block "$output"
  record_event "$package" "$phase" "validation" "failed" "$command" "$output"
  return "$status"
}

run_install_command() {
  local package_name="$1"
  shift
  local flags=("$@")
  local output=""
  local status=0

  local command_text="install $package_name"
  if ((${#flags[@]} > 0)); then
    command_text="$command_text ${flags[*]}"
  fi

  log "[simmer ]: $command_text"

  if $DRY_RUN; then
    log "      -> skip (dry-run)"

    if $capture_output; then
      record_event "$package_name" "simmer" "install" "dry-run" "$command_text" ""
    fi

    return 0
  fi

  if $capture_output; then
    local tmp
    tmp=$(mktemp)

    if install "$package_name" "${flags[@]}" >"$tmp" 2>&1; then
      output=$(<"$tmp")
      rm -f "$tmp"

      record_event "$package_name" "simmer" "install" "ok" "$command_text" "$output"
      return 0
    else
      status=$?
      output=$(<"$tmp")
      rm -f "$tmp"

      record_event "$package_name" "simmer" "install" "failed" "$command_text" "$output"
      log "      -> failed (exit $status)"
      return "$status"
    fi
  else
    if install "$package_name" "${flags[@]}"; then
      return 0
    else
      status=$?
      log "      -> failed (exit $status)"
      return "$status"
    fi
  fi
}

array_to_json() {
  local -n arr="$1"
  jq -cn '$ARGS.positional' --args "${arr[@]}"
}

print_summary() {
  local finished_at
  finished_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if [[ "$OUTPUT_FORMAT" == "human" ]]; then
    echo
    echo "Summary"
    echo "  Skip     : ${skip_packages[*]}"
    echo "  Dry Run  : ${dry_run_packages[*]}"
    echo "  Installed: ${installed_packages[*]}"
    echo "  Failed   : ${failed_packages[*]}"
    return 0
  fi

  local skip_json dry_json installed_json failed_json
  skip_json="$(array_to_json skip_packages)"
  dry_json="$(array_to_json dry_run_packages)"
  installed_json="$(array_to_json installed_packages)"
  failed_json="$(array_to_json failed_packages)"

  jq -n \
    --arg startedAt "$started_at" \
    --arg finishedAt "$finished_at" \
    --arg platform "$TARGET_PLATFORM" \
    --argjson dryRun "$DRY_RUN" \
    --argjson skipped "$skip_json" \
    --argjson dryRunPackages "$dry_json" \
    --argjson installed "$installed_json" \
    --argjson failed "$failed_json" \
    --argjson events "$events_json" \
    '{
      format_version: 1,
      started_at: $startedAt,
      finished_at: $finishedAt,
      platform: $platform,
      dry_run: $dryRun,
      summary: {
        skipped: $skipped,
        dry_run: $dryRunPackages,
        installed: $installed,
        failed: $failed,
        counts: {
          skipped: ($skipped | length),
          dry_run: ($dryRunPackages | length),
          installed: ($installed | length),
          failed: ($failed | length)
        }
      },
      events: $events
    }'
}

ensure_command() {
  local command="$1"
  local package="$2"

  if command -v "$command" >/dev/null 2>&1; then
    return
  fi

  log "[Kitchen]: stocking $package"

  if ! $DRY_RUN; then
    sudo apt update
    sudo apt install -y "$package"
  fi
}

ensure_command jq jq

load_manager() {
  local manager="$1"
  local manager_script="scripts/$manager.sh"

  if [[ ! -f "$manager_script" ]]; then
    echo "❌ Missing manager script: $manager_script" >&2
    exit 1
  fi

  source "$manager_script"
}

run_commands() {
  local package="$1"
  local label="$2"
  local json="$3"

  [[ "$json" == "null" ]] && return 0

  while read -r command; do

    run_eval_command "$package" "$label" "command" "$command" || return 1

  done < <(jq -r '.[]' <<<"$json")
}

while read -r entry; do

  name=$(jq -r '.key' <<<"$entry")

  recipe=$(jq -c --arg platform "$TARGET_PLATFORM" '.value[$platform]' <<<"$entry")

  [[ "$recipe" == "null" ]] && continue

  log "[Cook   ]: $name"

  manager=$(jq -r '.manager' <<<"$recipe")

  log "[pantry ]: $manager"

  skip_install=false
  load_manager "$manager"

  # Run validations to check if it is installed
  validations=$(jq -c '.validation // null' <<<"$recipe")

  if [[ "$validations" != "null" ]]; then

    validation_passed=true
    failed_validation_command=""

    while read -r command; do

      if ! run_validation_command "$name" "precheck" "$command" true; then
        validation_passed=false
        failed_validation_command="$command"
        break
      fi

    done < <(jq -r '.[]' <<<"$validations")

    if $validation_passed; then
      log "[stocked]: $name"
      record_event "$name" "precheck" "package-skip" "ok" "validation passed" ""
      skip_packages+=("$name")
      skip_install=true
    else
      log "    precheck failed: $failed_validation_command"
    fi

  fi

  if ! $skip_install; then
    # Run pre
    run_commands "$name" "prep" "$(jq -c '.pre // null' <<<"$recipe")"

    if jq -e '.package' <<<"$recipe" >/dev/null; then

      package=$(jq -r '.package' <<<"$recipe")
      flags=()
      mapfile -t flags < <(jq -r '.flags[]?' <<<"$recipe")

      if ! run_install_command "$package" "${flags[@]}"; then
        failed_packages+=("$name")
        continue
      fi
    fi

    if jq -e '.install' <<<"$recipe" >/dev/null; then

      run_commands "$name" "cook" "$(jq -c '.install' <<<"$recipe")"

    fi

    # Run post
    run_commands "$name" "season" "$(jq -c '.post // null' <<<"$recipe")"

    # Run validations
    if [[ "$validations" != "null" ]]; then

      validation_passed=true

      while read -r command; do

        if ! run_validation_command "$name" "taste" "$command"; then
          validation_passed=false
        fi

      done < <(jq -r '.[]' <<<"$validations")

      if $DRY_RUN; then
        dry_run_packages+=("$name")
      elif $validation_passed; then
        installed_packages+=("$name")
      else
        failed_packages+=("$name")
      fi
    fi
  fi

  log ""

done < <(jq -c 'to_entries[]' "$RECIPE_FILE")

print_summary
