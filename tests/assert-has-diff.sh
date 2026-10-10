#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../src/common.sh"

if [ "${HAS_DIFF}" != "${EXPECTED_HAS_DIFF}" ]; then
  log_error "Expected has-diff to be ${EXPECTED_HAS_DIFF}, got '${HAS_DIFF}'."
  exit 1
fi
