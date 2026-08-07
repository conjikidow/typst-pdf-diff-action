#!/bin/bash
set -euo pipefail

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
src_dir="${tests_dir}/../src"

# shellcheck disable=SC1091
source "${src_dir}/common.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "${work_dir}"' EXIT

status=0

run_case() {
  local name=$1
  local head_fixture=$2
  local expected_has_diff=$3

  local build="${work_dir}/${name}"
  local outputs="${build}/outputs"
  mkdir -p "${build}"
  : >"${outputs}"

  TARGET_FILES='sample.typ' SOURCE_DIR="${tests_dir}/fixtures/base" OUTPUT_DIR="${build}/base" \
    bash "${src_dir}/build-pdfs.sh"
  TARGET_FILES='sample.typ' SOURCE_DIR="${tests_dir}/fixtures/${head_fixture}" OUTPUT_DIR="${build}/head" \
    bash "${src_dir}/build-pdfs.sh"

  TARGET_FILES='sample.typ' BASE_DIR="${build}/base" HEAD_DIR="${build}/head" \
    DIFF_DIR="${build}/diff" META_DIR="${build}/meta" GITHUB_OUTPUT="${outputs}" \
    bash "${src_dir}/generate-diff.sh"

  local has_diff
  has_diff=$(sed -n 's/^has_diff=//p' "${outputs}")

  if [ "${has_diff}" != "${expected_has_diff}" ]; then
    log_error "${name}: expected has_diff to be ${expected_has_diff}, got '${has_diff}'."
    status=1
  fi

  if [ "${expected_has_diff}" = 'true' ] && [ ! -f "${build}/diff/sample.pdf" ]; then
    log_error "${name}: expected a diff PDF to be generated."
    status=1
  fi

  if [ "${expected_has_diff}" = 'false' ] && [ -f "${build}/diff/sample.pdf" ]; then
    log_error "${name}: expected no diff PDF to be left behind."
    status=1
  fi
}

run_case 'differing-sources' 'head' 'true'
run_case 'identical-sources' 'base' 'false'

exit "${status}"
