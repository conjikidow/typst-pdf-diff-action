#!/bin/bash
set -euo pipefail

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
src_dir="${tests_dir}/../src"

# shellcheck disable=SC1091
source "${src_dir}/common.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "${work_dir}"' EXIT

make_repo() {
  local repo="${work_dir}/$1"
  mkdir -p "${repo}/plain"
  git -C "${repo}" init --quiet
  git -C "${repo}" -c user.email='test@example.com' -c user.name='Test' \
    commit --quiet --allow-empty --message "$1"
  git -C "${repo}" rev-parse HEAD
}

head_sha=$(make_repo 'head-repo')
base_sha=$(make_repo 'base-repo')

status=0

run_case() {
  local name=$1
  local resolved_head=$2
  local resolved_base=$3
  local head_dir=$4
  local base_dir=$5
  local expected_head=$6
  local expected_base=$7

  local outputs="${work_dir}/outputs"
  : >"${outputs}"

  RESOLVED_HEAD_REF="${resolved_head}" RESOLVED_BASE_REF="${resolved_base}" \
    HEAD_DIR="${head_dir}" BASE_DIR="${base_dir}" GITHUB_OUTPUT="${outputs}" \
    bash "${src_dir}/determine-display-refs.sh" >/dev/null 2>&1

  local head_ref base_ref
  head_ref=$(sed -n 's/^head_ref=//p' "${outputs}")
  base_ref=$(sed -n 's/^base_ref=//p' "${outputs}")

  if [ "${head_ref}" != "${expected_head}" ]; then
    log_error "${name}: expected head_ref '${expected_head}', got '${head_ref}'."
    status=1
  fi

  if [ "${base_ref}" != "${expected_base}" ]; then
    log_error "${name}: expected base_ref '${expected_base}', got '${base_ref}'."
    status=1
  fi
}

run_case 'resolved revisions win' 'aaa111' 'bbb222' \
  "${work_dir}/head-repo" "${work_dir}/base-repo" 'aaa111' 'bbb222'
run_case 'revisions read from the working trees' '' '' \
  "${work_dir}/head-repo" "${work_dir}/base-repo" "${head_sha}" "${base_sha}"
run_case 'plain directories inside a repository' '' '' \
  "${work_dir}/head-repo/plain" "${work_dir}/base-repo/plain" 'head' 'base'

exit "${status}"
