#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

determine_revision() {
  local resolved="$1"
  local dir="$2"
  local role="$3"

  if [ -n "${resolved}" ]; then
    revision="${resolved}"
    return
  fi

  # Without this guard, rev-parse would walk up and report a parent repository.
  if [ -e "${dir}/.git" ] && revision="$(git -C "${dir}" rev-parse HEAD 2>/dev/null)"; then
    return
  fi

  log_warn "Unable to determine the ${role} revision from '${dir}'; labeling it as '${role}'."
  revision="${role}"
}

determine_revision "${RESOLVED_HEAD_REVISION}" "${HEAD_DIR}" 'head'
write_output 'head-revision' "${revision}"

determine_revision "${RESOLVED_BASE_REVISION}" "${BASE_DIR}" 'base'
write_output 'base-revision' "${revision}"
