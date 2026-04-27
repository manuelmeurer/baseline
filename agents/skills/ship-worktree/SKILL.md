---
name: ship-worktree
description: Commit current worktree changes and fast-forward merge into main. Use when the user asks to finish a feature in a git worktree by committing and merging into main, or simply says "ship" while the app is in a git worktree.
---

# Ship Worktree

You are finishing a feature in a git worktree.

**Goal:** land this worktree's commits on `main` (locally and on `origin`). The worktree branch itself is throwaway — never push the worktree branch ref to `origin`. Only `main` gets published. After shipping, the worktree branch exists only locally and can be deleted.

Do the following:

1. Run `git status --short` to show current status.
2. Run `git diff --stat HEAD` to show the diff summary.
3. Run `git log --oneline -5` to show recent commits on this branch.

## Commit

- If the user passed a commit message as an argument, stage everything and combine all changes into a single commit using that message.
- Otherwise, group related changes into logical commits — do not lump unrelated changes together in one commit. Write commit messages using the "Conventional Commits" format.

## Hard rules

- **Never use `git update-ref` to advance `main`.** It bypasses Git's safety net and silently desyncs the index/working tree of any worktree that has `main` checked out (you'll see phantom "deleted" / "modified" entries in `git status` there). If `git push . HEAD:main` is rejected because `main` is checked out elsewhere, do NOT reach for `update-ref` — push `HEAD` directly to `origin/main` and have the primary worktree pull with `git pull --ff-only`.
- Never ask the user to detach `HEAD` in another worktree.
- Never `push --force` and never push the worktree branch ref to `origin`. Only `main` gets published.

## Sync with origin

Run `git fetch origin`.

Then determine the state of the three relevant refs: `HEAD`, local `main`, and `origin/main`.

```sh
git rev-parse HEAD
git rev-parse main
git rev-parse origin/main
git merge-base --is-ancestor main origin/main && echo "local main is ancestor of origin/main" || echo "local main has commits not on origin/main"
git merge-base --is-ancestor origin/main HEAD && echo "HEAD is up to date with origin/main" || echo "HEAD is behind origin/main"
```

### Case A: clean fast-forward possible

Local `main` is an ancestor of `origin/main`, and `origin/main` is an ancestor of `HEAD`. Fast-forward local `main` to `HEAD`, then push `main` (not the worktree branch) to `origin`:

```sh
git push . HEAD:main
git push origin main
```

If `git push . HEAD:main` is rejected with `refusing to update checked out branch`, that means `main` is checked out in another worktree (typically the primary one). Do NOT use `git update-ref` to work around it, and do NOT ask the user to detach `HEAD` in the other worktree. Instead, push directly to `origin/main` from here and let the primary worktree fast-forward via `git pull --ff-only`:

```sh
git push origin HEAD:main
```

### Case B: branch is behind origin/main (easy case — handle automatically)

Local `main` is an ancestor of (or equal to) `origin/main`, but `origin/main` is NOT an ancestor of `HEAD`. This means `origin/main` has moved forward since this branch was created, but local `main` has no unpushed commits.

Rebase this branch onto `origin/main`, fast-forward local `main` to `HEAD`, then push `main` (not the worktree branch) to `origin`:

```sh
git rebase origin/main
git push . HEAD:main
git push origin main
```

If the rebase has conflicts, stop and report.

### Case C: local main has unpushed commits not in this branch (confirm with user)

Local `main` is NOT an ancestor of `origin/main` — local `main` has commits that haven't been pushed and aren't in this branch. A safe fast-forward of local `main` from this worktree is not possible without first publishing those commits.

Stop. Do NOT force-push. Do NOT auto-rebase. Do NOT cherry-pick.

Show the user the three SHAs (`HEAD`, local `main`, `origin/main`) and the commits unique to local `main`. The only thing to confirm is whether those local `main` commits are **ready to publish to `origin/main` now** (they might be WIP, not reviewed, etc.).

If yes, do this automatically — no further questions:

```sh
git push origin main:main           # publish local main's unpushed commits
git pull --rebase origin main       # rebase this branch on top
```

Then proceed with Case A.

If the user says no (local `main` commits aren't ready), stop and let them sort it out before retrying.

## Report

Report the final commit SHA and confirm `main` is up to date on origin.
