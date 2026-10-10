#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../src/common.sh"

tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
src_dir="${tests_dir}/../src"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

result_tsv="${work_dir}/diff-results.tsv"
printf '%s\thas-diff\t%s\n' 'main.typ' 'build/diff/main.pdf' >"${result_tsv}"

status=0

run_case() {
  local name="$1"
  local supplied_head_dir="$2"
  local note="$3"

  local body="${work_dir}/${name}.md"
  local outputs="${work_dir}/${name}.out"
  local line

  RESULT_TSV="${result_tsv}" DISPLAY_HEAD_REVISION='aaa111' DISPLAY_BASE_REVISION='bbb222' \
    HEAD_ARTIFACT_URL='' DIFF_ARTIFACT_URL='' HEAD_DIR="${supplied_head_dir}" COMMENT_FILE="${body}" \
    GITHUB_OUTPUT="${outputs}" bash "${src_dir}/build-comment.sh"

  if ! grep -qxF -- "comment-file=${body}" "${outputs}"; then
    log_error "${name}: expected the comment-file output to be '${body}'."
    status=1
  fi

  for line in "- Base revision: \`bbb222\`${note}" "- Head revision: \`aaa111\`${note}"; do
    if ! grep -qxF -- "${line}" "${body}"; then
      log_error "${name}: expected the body to contain the line '${line}'."
      status=1
    fi
  done
}

run_case 'checkout-mode' '' ''
run_case 'caller-supplied-mode' 'head-src' ' (caller-supplied working tree)'

exit "${status}"
