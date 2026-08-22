# Maintaining the Caelestia patch stack

This fork keeps its custom shell on `main` as a short patch stack above the
latest stable upstream release. The official repository's `stable` branch is
the source of truth; upstream `main` is deliberately not tracked.

## One-time local setup

The update script creates the `upstream` remote when it is missing. For normal
interactive updates, also enable Git's remembered conflict resolutions:

```sh
git config rerere.enabled true
git config rerere.autoupdate true
```

Do not push upstream's `v*` tags to this fork and do not create custom `v*`
tags. Caelestia uses those tags to derive its build version.

## GitHub setup

In the fork's **Settings → Actions → General**, grant workflows read/write
repository permissions and allow GitHub Actions to create pull requests. Keep
`main` configured so the promotion workflow can force-push; the workflow uses
an exact lease and is the only automated path allowed to replace it.

Run the existing **Update Docker CI image** workflow once before the first
update PR. It publishes `ghcr.io/skadewdl3/shell-arch-env:latest`, which the
inherited build, QML lint, and formatting jobs use. Confirm that Actions for
this repository can read the package if its initial visibility is private.

## Prepare an update locally

Start from a clean, current `main`:

```sh
git switch main
git pull --ff-only
scripts/update-upstream --check
scripts/update-upstream
```

The command creates `update/vX.Y.Z` and rebases every custom commit from the
old release tag onto the new one. To reproduce a particular update, pass its
tag explicitly, for example `scripts/update-upstream v2.4.0`.

If the rebase conflicts, resolve each file, stage it, and continue:

```sh
git add <resolved-files>
git rebase --continue
```

Use `git rebase --abort` to return to the pre-update state. After a successful
resolution, push the update branch and rerun the **Check for upstream release**
workflow; it will open the review PR without replacing the branch.

## Review and promote

The daily workflow performs the same checked rebase. A clean update is pushed
as `update/vX.Y.Z` and receives a PR so the complete build and lint suite can
run. A conflict produces an issue listing the affected paths.

The update PR is a review and CI surface only. Do not use GitHub's merge,
squash, or rebase buttons: those operations do not produce the desired rebased
history. Compare the resulting trees locally with:

```sh
git fetch origin
git diff origin/main..origin/update/vX.Y.Z
```

After every PR check succeeds, manually run **Promote upstream update** with
the PR number. It validates the exact tested SHA, creates
`archive/pre-vX.Y.Z` at the old `main`, and moves `main` using an exact
force-with-lease. The update branch is then removed.

## Roll back

Every promotion preserves the former main branch. To restore it, inspect the
archive first and then use the same guarded update pattern:

```sh
git fetch origin
git log --oneline origin/archive/pre-vX.Y.Z
git push --force-with-lease origin origin/archive/pre-vX.Y.Z:main
```

Scheduled workflows in inactive forks may be paused by GitHub. The update
workflow remains manually dispatchable, and `scripts/update-upstream --check`
always provides a local fallback.
