#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${GITHUB_ACTION_PATH}/src/common.sh"

require_cmd typst

mkdir -p "${OUTPUT_DIR}"

for file in ${TARGET_FILES}; do
  out="${OUTPUT_DIR}/${file%.typ}.pdf"
  mkdir -p "$(dirname "${out}")"
  typst compile --root "${SOURCE_DIR}" "${SOURCE_DIR}/${file}" "${out}"
done
