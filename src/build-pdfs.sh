#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${GITHUB_ACTION_PATH}/src/common.sh"

require_cmd typst

mkdir -p "${OUTPUT_DIR}"

for file in ${TARGET_FILES}; do
  source_file="${SOURCE_DIR}/${file}"
  out="${OUTPUT_DIR}/${file%.typ}.pdf"

  if [ ! -f "${source_file}" ]; then
    log_warn "Skipping missing Typst source: ${source_file}"
    continue
  fi

  mkdir -p "$(dirname "${out}")"
  typst compile --root "${SOURCE_DIR}" "${source_file}" "${out}"
done
