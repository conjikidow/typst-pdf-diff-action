#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../src/common.sh"

# Directories that the action checks the compared revisions out into.
base_dir='base-src'
head_dir='head-src'

status=0

# Recompute the merge-base from the event payload with local git, so that this
# assertion does not depend on the Compare API call that the action uses.
expected_base=$(git merge-base "${PR_BASE_SHA}" "${EXPECTED_HEAD}")
actual_base=$(git -C "${base_dir}" rev-parse HEAD)
actual_head=$(git -C "${head_dir}" rev-parse HEAD)

if [ "${actual_base}" != "${expected_base}" ]; then
  log_error "${base_dir} holds ${actual_base}, expected the merge-base ${expected_base}."
  status=1
fi

if [ "${actual_head}" != "${EXPECTED_HEAD}" ]; then
  log_error "${head_dir} holds ${actual_head}, expected ${EXPECTED_HEAD}."
  status=1
fi

exit "${status}"
