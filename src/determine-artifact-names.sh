#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

repo_name="${GITHUB_REPOSITORY#*/}"

if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] && [ -n "${PR_NUMBER}" ]; then
  suffix="pr-${PR_NUMBER}"
else
  head_ref_short="${HEAD_REF:0:7}"
  suffix="${head_ref_short}"
fi

write_output 'head_artifact_name' "${repo_name}-head-pdfs-${suffix}"
write_output 'diff_artifact_name' "${repo_name}-diff-pdfs-${suffix}"
