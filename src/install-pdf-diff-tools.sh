#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  diff-pdf-wx \
  xvfb

require_cmd diff-pdf
require_cmd xvfb-run

# xvfb-run prints its own errors to stderr and merges the wrapped command's stderr into stdout, so both streams are captured.
if ! output=$(xvfb-run --auto-servernum diff-pdf --help 2>&1); then
  log_error 'diff-pdf is installed but could not be executed.'
  echo "${output}" >&2
  exit 1
fi
