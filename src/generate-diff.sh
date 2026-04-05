#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${GITHUB_ACTION_PATH}/src/common.sh"

require_cmd diff-pdf
require_cmd xvfb-run

mkdir -p "${DIFF_DIR}" "${META_DIR}"
result_tsv="${META_DIR}/diff-results.tsv"
: > "${result_tsv}"

has_diff='false'
diff_count=0

for file in ${TARGET_FILES}; do
  rel="${file%.typ}"
  base_pdf="${BASE_DIR}/${rel}.pdf"
  head_pdf="${HEAD_DIR}/${rel}.pdf"
  diff_pdf="${DIFF_DIR}/${rel}.pdf"

  mkdir -p "$(dirname "${diff_pdf}")"

  if [ ! -f "${base_pdf}" ]; then
    printf '%s\tmissing-base\t\n' "${file}" >> "${result_tsv}"
    continue
  fi
  if [ ! -f "${head_pdf}" ]; then
    printf '%s\tmissing-head\t\n' "${file}" >> "${result_tsv}"
    continue
  fi

  set +e
  xvfb-run --auto-servernum diff-pdf \
    --skip-identical \
    --output-diff="${diff_pdf}" \
    "${base_pdf}" \
    "${head_pdf}"
  diff_rc=$?
  set -e

  if [ "${diff_rc}" -eq 0 ]; then
    printf '%s\tno-diff\t\n' "${file}" >> "${result_tsv}"
    continue
  fi
  if [ "${diff_rc}" -ne 1 ]; then
    log_error "diff-pdf failed for ${file}"
    exit "${diff_rc}"
  fi

  has_diff='true'
  diff_count=$((diff_count + 1))
  printf '%s\thas-diff\t%s\n' "${file}" "${diff_pdf}" >> "${result_tsv}"
done

{
  echo "has_diff=${has_diff}"
  echo "diff_count=${diff_count}"
  echo "result_tsv=${result_tsv}"
} >> "$GITHUB_OUTPUT"
