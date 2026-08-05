#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

head_ref=${INPUT_HEAD_REF}
base_ref=${INPUT_BASE_REF}

if [ -z "${head_ref}" ]; then
  if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] && [ -n "${PR_HEAD_SHA}" ]; then
    head_ref=${PR_HEAD_SHA}
  else
    head_ref=${GITHUB_SHA}
  fi
fi

if [ -z "${base_ref}" ]; then
  if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] && [ -n "${PR_BASE_SHA}" ]; then
    # Use the merge-base so the diff reflects only the changes introduced by this PR,
    # not unrelated commits merged into the base branch in the meantime.
    require_cmd gh
    base_ref=$(gh api "repos/${GITHUB_REPOSITORY}/compare/${PR_BASE_SHA}...${head_ref}" --jq '.merge_base_commit.sha')
    if [ -z "${base_ref}" ]; then
      log_error 'Failed to determine the merge-base via the GitHub Compare API.'
      exit 1
    fi
  else
    base_ref=${GITHUB_EVENT_BEFORE}
  fi
fi

if [ -z "${base_ref}" ] || [ "${base_ref}" = '0000000000000000000000000000000000000000' ]; then
  log_error 'Unable to determine the base revision. Set the base-ref input explicitly.'
  exit 1
fi

write_output 'head_ref' "${head_ref}"
write_output 'base_ref' "${base_ref}"
