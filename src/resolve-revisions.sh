#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

resolved_head_revision="${HEAD_REVISION}"
resolved_base_revision="${BASE_REVISION}"

if [ -z "${resolved_head_revision}" ]; then
  if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] && [ -n "${PR_HEAD_SHA}" ]; then
    resolved_head_revision="${PR_HEAD_SHA}"
  else
    resolved_head_revision="${GITHUB_SHA}"
  fi
fi

if [ -z "${resolved_base_revision}" ]; then
  if [ "${GITHUB_EVENT_NAME}" = 'pull_request' ] && [ -n "${PR_BASE_SHA}" ]; then
    # Use the merge-base so the diff reflects only the changes introduced by this PR,
    # not unrelated commits merged into the base branch in the meantime.
    require_cmd gh
    resolved_base_revision="$(gh api "repos/{owner}/{repo}/compare/${PR_BASE_SHA}...${resolved_head_revision}" --jq '.merge_base_commit.sha')"
    if [ -z "${resolved_base_revision}" ]; then
      log_error 'Failed to determine the merge-base via the GitHub Compare API.'
      exit 1
    fi
  else
    resolved_base_revision="${PUSH_BEFORE_SHA}"
  fi
fi

if [ -z "${resolved_base_revision}" ] || [ "${resolved_base_revision}" = '0000000000000000000000000000000000000000' ]; then
  log_error 'Unable to determine the base revision. Set the base-revision input explicitly.'
  exit 1
fi

write_output 'head-revision' "${resolved_head_revision}"
write_output 'base-revision' "${resolved_base_revision}"
