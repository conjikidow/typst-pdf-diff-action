#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

determine_ref() {
  local resolved=$1
  local dir=$2
  local role=$3

  if [ -n "${resolved}" ]; then
    ref=${resolved}
    return
  fi

  # Without this guard, rev-parse would walk up and report a parent repository.
  if [ -e "${dir}/.git" ] && ref=$(git -C "${dir}" rev-parse HEAD 2>/dev/null); then
    return
  fi

  log_warn "Unable to determine the ${role} revision from '${dir}'; labeling it as '${role}'."
  ref=${role}
}

determine_ref "${RESOLVED_HEAD_REF}" "${HEAD_DIR}" 'head'
write_output 'head_ref' "${ref}"

determine_ref "${RESOLVED_BASE_REF}" "${BASE_DIR}" 'base'
write_output 'base_ref' "${ref}"
