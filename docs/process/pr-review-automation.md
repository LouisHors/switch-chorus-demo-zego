# PR review automation

This repository now has two review layers:

1. Local git hooks for commit / push time checks.
2. GitHub Actions for pull request quality gates and AI review.

## Local setup

Run this once after pulling:

```bash
./scripts/install-dev-hooks.sh
```

That configures `core.hooksPath` to `.githooks`, which preserves beads hooks and adds:

- `pre-commit`: staged diff sanity checks via `git diff --cached --check`
- `pre-push`: local Xcode build gate via `./scripts/ci/xcode-build.sh`

If you absolutely need to bypass a gate:

```bash
SKIP_LOCAL_CHECKS=1 git commit ...
SKIP_LOCAL_BUILD=1 git push ...
```

Use the bypass sparingly and explain why in the PR.

## Pull request checks

### Deterministic CI

`PR Quality Gate` runs on every non-draft PR update and executes:

```bash
./scripts/ci/xcode-build.sh
```

### Claude review

`Claude PR Review` is wired for GitHub Actions.

To enable it, add a repository secret named `ANTHROPIC_API_KEY`.

Behavior:

- When the secret exists, Claude reviews every non-draft PR update.
- Anyone can comment `@claude review` on a PR to request another pass.

## Codex plugin workflow

Your current flow can stay the same:

- Use Claude Code for implementation.
- Use the Codex plugin for the final human-triggered review before merge.
- Let local hooks and PR workflows catch obvious regressions automatically.

This gives you a three-layer gate: local checks, PR CI, and AI review.
