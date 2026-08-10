#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [ -z "${HEAD_DIR}" ] && [ -z "${BASE_DIR}" ]; then
  exit 0
fi

if [ -z "${HEAD_DIR}" ] || [ -z "${BASE_DIR}" ]; then
  log_error 'head-dir and base-dir must be set together, or both left empty to let the action check out the sources.'
  exit 1
fi

for dir in "${HEAD_DIR}" "${BASE_DIR}"; do
  if [ ! -d "${dir}" ]; then
    log_error "Working tree not found: ${dir}"
    exit 1
  fi
done

if [ "$(cd "${HEAD_DIR}" && pwd -P)" = "$(cd "${BASE_DIR}" && pwd -P)" ]; then
  log_error 'head-dir and base-dir must point to different directories.'
  exit 1
fi

if [ "${SUBMODULES}" != 'false' ]; then
  log_error 'submodules has no effect when head-dir and base-dir are set, because the action does not check out the sources.'
  exit 1
fi

if [ -n "${HEAD_REF}" ] || [ -n "${BASE_REF}" ]; then
  log_error 'head-ref and base-ref have no effect when head-dir and base-dir are set, because the compared revisions are read from those directories.'
  exit 1
fi
