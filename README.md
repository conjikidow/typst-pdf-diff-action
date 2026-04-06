# typst-pdf-diff-action

Generate PDF diffs for Typst documents in GitHub Actions.

> [!WARNING]
> This project is in early development. The API may change in future releases.

## Features

- Builds Typst documents from separate base and head revisions.
- Generates diff PDFs with [`diff-pdf`](https://github.com/vslavik/diff-pdf).
- Uploads head PDFs and diff PDFs as workflow artifacts.
- Optionally creates or updates a pull request comment.

## Usage

### Workflow Example

The following workflow runs on pull requests, compares the PR head against the
PR base, uploads the generated PDFs, and updates a PR comment.

```yaml
name: Typst PDF Diff

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  typst-pdf-diff:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - name: Generate Typst PDF diff
        uses: conjikidow/typst-pdf-diff-action@v0.1.0
        with:
          target-files: main.typ
```

If your Typst project uses submodules, set `submodules: 'recursive'` and pass a
token that can access those submodules.

```yaml
name: Typst PDF Diff

on:
  pull_request:
    types: [opened, synchronize, reopened]

env:
  TYPST_TARGET_FILES: paper/main.typ slides/main.typ

jobs:
  typst-pdf-diff:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/create-github-app-token@v3
        id: generate-token
        with:
          app-id: ${{ vars.APP_ID }}
          private-key: ${{ secrets.PRIVATE_KEY }}
      - name: Generate Typst PDF diff
        uses: conjikidow/typst-pdf-diff-action@v0.1.0
        with:
          target-files: ${{ env.TYPST_TARGET_FILES }}
          github-token: ${{ steps.generate-token.outputs.token }}
          submodules: 'recursive'
```

For non-PR events, set `head-ref` and `base-ref` explicitly if you do not want
to rely on the action's automatic revision resolution.

### Inputs

<!-- markdownlint-disable MD013 -->
| Name                    | Description                                                                        | Required | Default               |
| ----------------------- | ---------------------------------------------------------------------------------- | -------- | --------------------- |
| `target-files`          | Space-separated Typst entrypoint files to compile.                                 | Yes      | -                     |
| `typst-version`         | The Typst version to install.                                                      | No       | `'latest'`            |
| `github-token`          | The GitHub Token for checkout, artifact upload, and comments.                      | No       | `${{ github.token }}` |
| `submodules`            | `actions/checkout` submodule mode: `false`, `true`, or `recursive`.                | No       | `'false'`             |
| `head-ref`              | Head revision to compare. If empty, uses the PR head SHA or `github.sha`.          | No       | `''`                  |
| `base-ref`              | Base revision to compare. If empty, uses the PR base SHA or `github.event.before`. | No       | `''`                  |
| `post-comment`          | Whether to update a pull request comment with diff results.                        | No       | `'true'`              |
| `comment-mode`          | Comment update mode: `replace` or `append`.                                        | No       | `'replace'`           |
| `fail-on-comment-error` | Whether to fail the action when PR comment updates fail.                           | No       | `'false'`             |
| `upload-artifacts`      | Whether to upload head and diff PDFs as workflow artifacts.                        | No       | `'true'`              |
<!-- markdownlint-enable MD013 -->

<!-- markdownlint-disable MD028 -->
> [!TIP]
> `target-files` is interpreted as a space-separated list. For example:
> `main.typ appendix.typ`.

> [!IMPORTANT]
> `post-comment: 'true'` is intended for `pull_request` events.
> On other events, the action skips pull request comment updates.
<!-- markdownlint-enable MD028 -->

### Outputs

| Name                | Description                                                          |
| ------------------- | -------------------------------------------------------------------- |
| `has-diff`          | `true` when at least one target file produces a diff PDF.            |
| `head-artifact-url` | The uploaded head PDF artifact URL when artifact upload is enabled.  |
| `diff-artifact-url` | The uploaded diff PDF artifact URL when a diff artifact is uploaded. |

## How It Works

1. Resolves the base and head revisions.
2. Checks out the head revision and the base revision into separate directories.
3. Installs Typst and `diff-pdf`.
4. Builds PDFs for all `target-files` from both revisions.
5. Generates diff PDFs with `diff-pdf`.
6. Uploads head PDFs and diff PDFs as artifacts when enabled.
7. Builds a Markdown summary and optionally updates a PR comment.

## Contributing & Feedback

Contributions, bug reports, and feedback are always welcome!
Thank you for helping improve this project for everyone!
