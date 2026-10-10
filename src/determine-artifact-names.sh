#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

repo_name="${GITHUB_REPOSITORY#*/}"

if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] && [ -n "${PR_NUMBER}" ]; then
  suffix="pr-${PR_NUMBER}"
else
  head_revision_short="${DISPLAY_HEAD_REVISION:0:7}"
  suffix="${head_revision_short}"
fi

write_output 'head-artifact-name' "${repo_name}-head-pdfs-${suffix}"
write_output 'diff-artifact-name' "${repo_name}-diff-pdfs-${suffix}"
