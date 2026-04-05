#!/bin/bash
set -euo pipefail

log_info() {
  echo "$*"
}

log_warn() {
  echo "::warning::$*"
}

log_error() {
  echo "::error::$*"
}

require_cmd() {
  local cmd=$1
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "Required command not found: ${cmd}"
    exit 1
  fi
}

write_output() {
  local key=$1
  local value=$2
  echo "${key}=${value}" >> "$GITHUB_OUTPUT"
}

normalize_bool() {
  local value=$1
  case "$value" in
    true|false)
      printf '%s\n' "$value"
      ;;
    *)
      log_error "Invalid boolean value: ${value}"
      exit 1
      ;;
  esac
}
