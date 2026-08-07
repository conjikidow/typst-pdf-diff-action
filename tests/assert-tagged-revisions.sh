#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../src/common.sh"

# Directories that the action checks the compared revisions out into.
base_dir='base-src'
head_dir='head-src'

status=0

expected_base=$(git rev-parse "${BASE_REV}^{commit}")
expected_head=$(git rev-parse "${HEAD_REV}^{commit}")
actual_base=$(git -C "${base_dir}" rev-parse HEAD)
actual_head=$(git -C "${head_dir}" rev-parse HEAD)

if [ "${actual_base}" != "${expected_base}" ]; then
  log_error "${base_dir} holds ${actual_base}, expected ${BASE_REV} (${expected_base})."
  status=1
fi

if [ "${actual_head}" != "${expected_head}" ]; then
  log_error "${head_dir} holds ${actual_head}, expected ${HEAD_REV} (${expected_head})."
  status=1
fi

if [ "${HAS_DIFF}" != 'false' ]; then
  log_error "Expected has-diff to be false because the target file is absent, got '${HAS_DIFF}'."
  status=1
fi

exit "${status}"
