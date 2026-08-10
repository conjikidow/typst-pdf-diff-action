#!/bin/bash
set -euo pipefail

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
src_dir="${tests_dir}/../src"

# shellcheck disable=SC1091
source "${src_dir}/common.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "${work_dir}"' EXIT

result_tsv="${work_dir}/diff-results.tsv"
printf '%s\thas-diff\t%s\n' 'main.typ' 'build/diff/main.pdf' >"${result_tsv}"

status=0

run_case() {
  local name=$1
  local supplied_head_dir=$2
  local note=$3

  # build-comment.sh writes to a fixed path relative to the working directory.
  local case_dir="${work_dir}/${name}"
  mkdir -p "${case_dir}/build/meta"

  (
    cd "${case_dir}"
    RESULT_TSV="${result_tsv}" HAS_DIFF='true' HEAD_REF='aaa111' BASE_REF='bbb222' \
      HEAD_ARTIFACT_URL='' DIFF_ARTIFACT_URL='' SUPPLIED_HEAD_DIR="${supplied_head_dir}" \
      bash "${src_dir}/build-comment.sh"
  )

  local body="${case_dir}/build/meta/pr-comment.md"
  local line

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
