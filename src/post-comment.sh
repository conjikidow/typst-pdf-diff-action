#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${GITHUB_ACTION_PATH}/src/common.sh"

if [ "${GITHUB_EVENT_NAME}" != 'pull_request' ] || [ -z "${PR_NUMBER}" ]; then
  log_warn 'Skipping pull request comment update because this is not a pull_request event.'
  exit 0
fi

require_cmd gh
require_cmd jq

if [ ! -f "${COMMENT_FILE}" ]; then
  log_warn "Skipping pull request comment update because ${COMMENT_FILE} was not generated."
  exit 0
fi

marker='<!-- typst-pdf-diff-review -->'
list_endpoint="repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments"

run_comment_call() {
  local status=0

  if [ "${COMMENT_MODE}" = 'replace' ]; then
    if ! existing_ids=$(gh api "${list_endpoint}" --paginate \
      --jq ".[] | select(.user.login == \"github-actions[bot]\") | select(.body | contains(\"${marker}\")) | .id"); then
      return 1
    fi

    for comment_id in ${existing_ids}; do
      if ! gh api -X DELETE "repos/${GITHUB_REPOSITORY}/issues/comments/${comment_id}"; then
        status=1
      fi
    done
  elif [ "${COMMENT_MODE}" != 'append' ]; then
    log_error "Unsupported comment mode: ${COMMENT_MODE}"
    exit 1
  fi

  body_json=$(jq -Rs '{body: .}' "${COMMENT_FILE}")
  if ! gh api "${list_endpoint}" --method POST --input - <<< "${body_json}"; then
    status=1
  fi

  return "${status}"
}

if run_comment_call; then
  exit 0
fi

if [ "$(normalize_bool "${FAIL_ON_COMMENT_ERROR}")" = 'true' ]; then
  log_error 'Failed to update the pull request comment.'
  exit 1
fi

log_warn 'Failed to update the pull request comment.'
