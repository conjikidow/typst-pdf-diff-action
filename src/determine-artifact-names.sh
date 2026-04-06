#!/bin/bash
set -euo pipefail

repo_name="${GITHUB_REPOSITORY#*/}"

if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] && [ -n "${PR_NUMBER}" ]; then
  suffix="pr-${PR_NUMBER}"
else
  head_ref_short="${HEAD_REF:0:7}"
  suffix="${head_ref_short}"
fi

{
  echo "head_artifact_name=${repo_name}-head-pdfs-${suffix}"
  echo "diff_artifact_name=${repo_name}-diff-pdfs-${suffix}"
} >>"$GITHUB_OUTPUT"
