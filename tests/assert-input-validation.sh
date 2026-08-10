#!/bin/bash
set -euo pipefail

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
src_dir="${tests_dir}/../src"

# shellcheck disable=SC1091
source "${src_dir}/common.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "${work_dir}"' EXIT
mkdir -p "${work_dir}/head" "${work_dir}/base"

status=0

# Remaining arguments override the default inputs as VAR=VALUE assignments.
run_case() {
  local name=$1
  local expected_rc=$2
  shift 2

  local rc=0
  env HEAD_DIR='' BASE_DIR='' SUBMODULES='false' HEAD_REF='' BASE_REF='' "$@" \
    bash "${src_dir}/validate-inputs.sh" >/dev/null 2>&1 || rc=$?

  if [ "${rc}" -ne "${expected_rc}" ]; then
    log_error "${name}: expected exit ${expected_rc}, got ${rc}."
    status=1
  fi
}

both_dirs=(HEAD_DIR="${work_dir}/head" BASE_DIR="${work_dir}/base")

run_case 'no directories' 0
run_case 'both directories' 0 "${both_dirs[@]}"
run_case 'only head-dir' 1 HEAD_DIR="${work_dir}/head"
run_case 'only base-dir' 1 BASE_DIR="${work_dir}/base"
run_case 'missing head directory' 1 HEAD_DIR="${work_dir}/absent" BASE_DIR="${work_dir}/base"
run_case 'missing base directory' 1 HEAD_DIR="${work_dir}/head" BASE_DIR="${work_dir}/absent"
run_case 'identical directories' 1 HEAD_DIR="${work_dir}/head" BASE_DIR="${work_dir}/head"
run_case 'submodules with directories' 1 "${both_dirs[@]}" SUBMODULES='recursive'
run_case 'head-ref with directories' 1 "${both_dirs[@]}" HEAD_REF='aaa111'
run_case 'base-ref with directories' 1 "${both_dirs[@]}" BASE_REF='bbb222'
run_case 'refs without directories' 0 HEAD_REF='aaa111' BASE_REF='bbb222'

exit "${status}"
