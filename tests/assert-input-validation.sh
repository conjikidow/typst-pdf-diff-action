#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../src/common.sh"

tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
src_dir="${tests_dir}/../src"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
mkdir -p "${work_dir}/base" "${work_dir}/head"

status=0

# Remaining arguments override the default inputs as VAR=VALUE assignments.
run_case() {
  local name="$1"
  local expected_rc="$2"
  shift 2

  local rc=0
  env SUBMODULES='false' BASE_REVISION='' HEAD_REVISION='' POST_COMMENT='true' COMMENT_MODE='replace' \
    FAIL_ON_COMMENT_ERROR='false' UPLOAD_ARTIFACTS='true' BASE_DIR='' HEAD_DIR='' "$@" \
    bash "${src_dir}/validate-inputs.sh" > /dev/null 2>&1 || rc="$?"

  if [[ ${rc} -ne ${expected_rc} ]]; then
    log_error "${name}: expected exit ${expected_rc}, got ${rc}."
    status=1
  fi
}

both_dirs=(BASE_DIR="${work_dir}/base" HEAD_DIR="${work_dir}/head")

run_case 'no directories' 0
run_case 'recursive submodules' 0 SUBMODULES='recursive'
run_case 'capitalized submodules' 0 SUBMODULES='True'
run_case 'invalid submodules' 1 SUBMODULES='yes'
run_case 'empty submodules' 1 SUBMODULES=''
run_case 'capitalized booleans' 0 POST_COMMENT='TRUE' FAIL_ON_COMMENT_ERROR='False' UPLOAD_ARTIFACTS='True'
run_case 'mixed-case boolean' 1 POST_COMMENT='tRuE'
run_case 'invalid post-comment' 1 POST_COMMENT='yes'
run_case 'empty post-comment' 1 POST_COMMENT=''
run_case 'append comment-mode' 0 COMMENT_MODE='append'
run_case 'capitalized comment-mode' 1 COMMENT_MODE='Replace'
run_case 'empty comment-mode' 1 COMMENT_MODE=''
run_case 'invalid comment-mode' 1 COMMENT_MODE='update'
run_case 'invalid fail-on-comment-error' 1 FAIL_ON_COMMENT_ERROR='yes'
run_case 'invalid upload-artifacts' 1 UPLOAD_ARTIFACTS='1'
run_case 'both directories' 0 "${both_dirs[@]}"
run_case 'only base-dir' 1 BASE_DIR="${work_dir}/base"
run_case 'only head-dir' 1 HEAD_DIR="${work_dir}/head"
run_case 'missing base directory' 1 BASE_DIR="${work_dir}/absent" HEAD_DIR="${work_dir}/head"
run_case 'missing head directory' 1 BASE_DIR="${work_dir}/base" HEAD_DIR="${work_dir}/absent"
run_case 'identical directories' 1 BASE_DIR="${work_dir}/head" HEAD_DIR="${work_dir}/head"
run_case 'submodules with directories' 1 "${both_dirs[@]}" SUBMODULES='recursive'
run_case 'capitalized false submodules with directories' 0 "${both_dirs[@]}" SUBMODULES='False'
run_case 'base-revision with directories' 1 "${both_dirs[@]}" BASE_REVISION='bbb222'
run_case 'head-revision with directories' 1 "${both_dirs[@]}" HEAD_REVISION='aaa111'
run_case 'revisions without directories' 0 BASE_REVISION='bbb222' HEAD_REVISION='aaa111'

exit "${status}"
