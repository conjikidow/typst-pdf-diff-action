#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${GITHUB_ACTION_PATH}/src/common.sh"

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  diff-pdf-wx \
  xvfb

require_cmd diff-pdf
require_cmd xvfb-run

if ! xvfb-run --auto-servernum diff-pdf --help >/dev/null 2>&1; then
  log_error 'diff-pdf is installed but could not be executed.'
  exit 1
fi
