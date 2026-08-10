# Typst PDF Diff Action

A GitHub Action to generate PDF diffs for Typst documents.

> [!WARNING]
> This project is in early development. The API may change in future releases.

## Features

- Builds Typst documents from separate base and head revisions.
- Generates diff PDFs with [`diff-pdf`](https://github.com/vslavik/diff-pdf).
- Uploads head PDFs and diff PDFs as workflow artifacts.
- Optionally creates or updates a pull request comment.

## Usage

### Workflow Example

The following workflow runs on pull requests, compares the PR head against
the merge-base (the commit where the PR branched off the base branch),
uploads the generated PDFs, and updates a PR comment.

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
        uses: conjikidow/typst-pdf-diff-action@v0.3.0
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
          client-id: ${{ vars.GH_APP_CLIENT_ID }}
          private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
      - name: Generate Typst PDF diff
        uses: conjikidow/typst-pdf-diff-action@v0.3.0
        with:
          target-files: ${{ env.TYPST_TARGET_FILES }}
          github-token: ${{ steps.generate-token.outputs.token }}
          submodules: 'recursive'
```

> [!IMPORTANT]
> A GitHub App installation token is scoped to a single account,
> so it cannot read submodules owned by another user or organization.
> `actions/checkout` fails the whole job when any submodule cannot be fetched.
> If your submodules span several owners, prepare the working trees yourself as described in
> [Bring Your Own Working Trees](#bring-your-own-working-trees).

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
| `base-ref`              | Base revision to compare. If empty, uses the merge-base or `github.event.before`.  | No       | `''`                  |
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

#### Advanced Inputs

These are only needed when the action cannot check out the sources itself.
See [Bring Your Own Working Trees](#bring-your-own-working-trees).

<!-- markdownlint-disable MD013 -->
| Name       | Description                                                                        | Required | Default |
| ---------- | ---------------------------------------------------------------------------------- | -------- | ------- |
| `head-dir` | Existing working tree to build the head revision from. Disables checkout when set. | No       | `''`    |
| `base-dir` | Existing working tree to build the base revision from. Requires `head-dir`.        | No       | `''`    |
<!-- markdownlint-enable MD013 -->

Both must be set together, and `submodules`, `head-ref`, and `base-ref` must stay at their defaults,
because the action checks out nothing in this mode.
Any other combination fails immediately.

### Outputs

| Name                | Description                                                          |
| ------------------- | -------------------------------------------------------------------- |
| `has-diff`          | `true` when at least one target file produces a diff PDF.            |
| `head-artifact-url` | The uploaded head PDF artifact URL when artifact upload is enabled.  |
| `diff-artifact-url` | The uploaded diff PDF artifact URL when a diff artifact is uploaded. |

### Bring Your Own Working Trees

Set `head-dir` and `base-dir` when the action cannot check out the sources itself,
for example when your submodules live under more than one owner and therefore need separate tokens.
The action then builds and compares the directories you provide, and checks out nothing.

Resolving the base revision is then up to you.
For a pull request, compare against the merge-base rather than the base branch tip,
or the diff will also contain unrelated changes merged into the base branch in the meantime.

```yaml
      - uses: actions/create-github-app-token@v3
        id: app-token
        with:
          client-id: ${{ vars.GH_APP_CLIENT_ID }}
          private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
          repositories: private-submodule

      - name: Resolve the merge-base
        id: merge-base
        env:
          GH_TOKEN: ${{ github.token }}
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
        run: |
          sha=$(gh api "repos/${GITHUB_REPOSITORY}/compare/${BASE_SHA}...${HEAD_SHA}" --jq '.merge_base_commit.sha')
          echo "sha=${sha}" >>"$GITHUB_OUTPUT"

      - uses: actions/checkout@v7
        with:
          path: head-src
          ref: ${{ github.event.pull_request.head.sha }}
          persist-credentials: false

      - uses: actions/checkout@v7
        with:
          path: base-src
          ref: ${{ steps.merge-base.outputs.sha }}
          persist-credentials: false

      - name: Check out the required submodules
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          git config --global --add url."https://x-access-token:${GH_TOKEN}@github.com/".insteadOf git@github.com:
          git config --global --add url."https://x-access-token:${GH_TOKEN}@github.com/".insteadOf https://github.com/
          for dir in head-src base-src; do
            git -C "${dir}" submodule update --init --depth 1 private-submodule
          done

      - name: Generate Typst PDF diff
        uses: conjikidow/typst-pdf-diff-action@v0.3.0
        with:
          target-files: paper/main.typ
          head-dir: head-src
          base-dir: base-src
```

That example uses a single token.
When your submodules span several owners, qualify each rewrite with the owner so that the longest match wins.
Identical prefixes resolve to whichever token was configured first,
which silently sends one owner's token to another owner.

```sh
git config --global --add \
  url."https://x-access-token:${TOKEN_A}@github.com/owner-a/".insteadOf git@github.com:owner-a/
git config --global --add \
  url."https://x-access-token:${TOKEN_B}@github.com/owner-b/".insteadOf git@github.com:owner-b/
```

The action writes its build output to `build/` in the workspace,
so do not point `head-dir` or `base-dir` inside that directory.

> [!CAUTION]
> The action cannot verify that the directories you supply hold the revisions you intended.

## How It Works

1. Resolves the base and head revisions, and checks them out into separate directories.
   Both steps are skipped when `head-dir` and `base-dir` are provided.
2. Installs Typst and `diff-pdf`.
3. Builds PDFs for all `target-files` from both revisions.
4. Generates diff PDFs with `diff-pdf`.
5. Uploads head PDFs and diff PDFs as artifacts when enabled.
6. Builds a Markdown summary and optionally updates a PR comment.

## Contributing & Feedback

Contributions, bug reports, and feedback are always welcome!
Thank you for helping improve this project for everyone!
