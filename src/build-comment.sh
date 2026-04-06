#!/bin/bash
set -euo pipefail

comment_file='build/meta/pr-comment.md'
marker='<!-- typst-pdf-diff-review -->'

{
  echo "${marker}"
  echo '## Typst PDF Diff Review'
  echo
  echo "- Base revision: \`${BASE_REF}\`"
  echo "- Head revision: \`${HEAD_REF}\`"
  if [ -n "${HEAD_ARTIFACT_URL}" ]; then
    echo "- Head PDFs artifact: [typst-head-pdfs](${HEAD_ARTIFACT_URL})"
  fi
  if [ "${HAS_DIFF}" = 'true' ]; then
    if [ -n "${DIFF_ARTIFACT_URL}" ]; then
      echo "- Diff PDFs artifact: [typst-diff-pdfs](${DIFF_ARTIFACT_URL})"
    fi
  else
    echo '- PDF diff: No differences detected.'
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
