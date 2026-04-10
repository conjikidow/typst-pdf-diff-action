#!/bin/bash
set -euo pipefail

comment_file='build/meta/pr-comment.md'
marker='<!-- typst-pdf-diff-review -->'
has_missing='false'
missing_count=0
diff_count=0
no_diff_count=0

while IFS=$'\t' read -r _file status _diff_pdf; do
  case "${status}" in
  has-diff) diff_count=$((diff_count + 1)) ;;
  no-diff) no_diff_count=$((no_diff_count + 1)) ;;
  missing-base | missing-head)
    has_missing='true'
    missing_count=$((missing_count + 1))
    ;;
  esac
done <"${RESULT_TSV}"

{
  echo "${marker}"
  echo '## Typst PDF Diff Review'
  echo
  echo "- Base revision: \`${BASE_REF}\`"
  echo "- Head revision: \`${HEAD_REF}\`"
  if [ -n "${HEAD_ARTIFACT_URL}" ]; then
    echo "- Head PDFs artifact: [typst-head-pdfs](${HEAD_ARTIFACT_URL})"
  fi
  if [ "${diff_count}" -gt 0 ] && [ -n "${DIFF_ARTIFACT_URL}" ]; then
    echo "- Diff PDFs artifact: [typst-diff-pdfs](${DIFF_ARTIFACT_URL})"
  fi
  if [ "${diff_count}" -gt 0 ]; then
    if [ "${has_missing}" = 'true' ]; then
      echo "- PDF diff: Generated for ${diff_count} file(s); skipped ${missing_count} missing file(s)."
    else
      echo "- PDF diff: Differences detected in ${diff_count} file(s)."
    fi
  else
    if [ "${has_missing}" = 'true' ]; then
      echo '- PDF diff: Skipped for files missing on either the base or head revision.'
    else
      echo '- PDF diff: No differences detected.'
    fi
  fi
  echo
  echo '| File | Status |'
  echo '| --- | --- |'
  while IFS=$'\t' read -r file status _diff_pdf; do
    case "${status}" in
    has-diff) status_text='diff found' ;;
    no-diff) status_text='no diff' ;;
    missing-base) status_text='base missing' ;;
    missing-head) status_text='head missing' ;;
    *) status_text="${status}" ;;
    esac
    printf "| \`%s\` | %s |\n" "${file}" "${status_text}"
  done <"${RESULT_TSV}"
} >"${comment_file}"
