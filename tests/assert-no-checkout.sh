#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../src/common.sh"

status=0

for dir in head-src base-src; do
  if [ -e "${dir}" ]; then
    log_error "${dir} exists; the action must not check out sources when working trees are supplied."
    status=1
  fi
done

exit "${status}"
