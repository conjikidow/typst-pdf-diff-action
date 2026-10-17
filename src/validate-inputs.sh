#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

if [[ -z ${BASE_DIR} && -z ${HEAD_DIR} ]]; then
  exit 0
fi

if [[ -z ${BASE_DIR} || -z ${HEAD_DIR} ]]; then
  log_error 'base-dir and head-dir must be set together, or both left empty to let the action check out the sources.'
  exit 1
fi

for dir in "${BASE_DIR}" "${HEAD_DIR}"; do
  if [[ ! -d ${dir} ]]; then
    log_error "Working tree not found: ${dir}"
    exit 1
  fi
done

if [[ "$(cd "${BASE_DIR}" && pwd -P)" == "$(cd "${HEAD_DIR}" && pwd -P)" ]]; then
  log_error 'base-dir and head-dir must point to different directories.'
  exit 1
fi

if [[ ${SUBMODULES} != 'false' ]]; then
  log_error 'submodules has no effect when base-dir and head-dir are set, because the action does not check out the sources.'
  exit 1
fi

if [[ -n ${BASE_REVISION} || -n ${HEAD_REVISION} ]]; then
  log_error 'base-revision and head-revision have no effect when base-dir and head-dir are set, because the compared revisions are read from those directories.'
  exit 1
fi
