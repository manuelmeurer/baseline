---
name: ship-worktree
description: Commit current worktree changes and fast-forward merge into main. Use when the user asks to finish a feature in a git worktree by committing and merging into main, or simply says "ship" while the app is in a git worktree.
---

# Ship Worktree

You are finishing a feature in a git worktree. Do the following:

1. Run `git status --short` to show current status.
2. Run `git diff --stat HEAD` to show the diff summary.
3. Run `git log --oneline -5` to show recent commits on this branch.

## Commit

- If the user passed a commit message as an argument, stage everything and combine all changes into a single commit using that message.
- Otherwise, group related changes into logical commits — do not lump unrelated changes together in one commit. Write commit messages using the "Conventional Commits" format.

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

Local `main` is an ancestor of `origin/main`, and `origin/main` is an ancestor of `HEAD`. Proceed:

```sh
git push . HEAD:main
git push origin main
```

### Case B: branch is behind origin/main (easy case — handle automatically)

Local `main` is an ancestor of (or equal to) `origin/main`, but `origin/main` is NOT an ancestor of `HEAD`. This means `origin/main` has moved forward since this branch was created, but local `main` has no unpushed commits.

Rebase this branch onto `origin/main`, then push:

```sh
git rebase origin/main
git push . HEAD:main
git push origin main
```

If the rebase has conflicts, stop and report.

### Case C: local main has unpushed commits not in this branch (hard case — ask the user)

Local `main` is NOT an ancestor of `origin/main` — local `main` has commits that haven't been pushed and aren't in this branch. A safe fast-forward of local `main` from this worktree is not possible without losing or duplicating those commits.

Stop. Do NOT force-push. Do NOT auto-rebase. Do NOT cherry-pick without asking.

Explain the situation to the user, showing the three SHAs (`HEAD`, local `main`, `origin/main`) and which commits are unique to local `main`. Then suggest these options:

1. **Push branch directly to origin/main, sync local main afterward.** Run `git push origin HEAD:main` from this worktree. Then in the primary worktree run `git pull --rebase` on `main` to replay the unpushed commit on top, and `git push origin main` to publish it. Simplest if the user wants to finish in this worktree now.
2. **Push local main's commits first, then rebase here and ship normally.** User pushes local `main` from the primary worktree, then this worktree runs `git pull --rebase origin main` and proceeds with Case A. Cleanest linear history, no orphaned commits.
3. **Cherry-pick the local main commits into this branch and force-update local main.** Risky; leaves the original SHAs orphaned. Only suggest if the user explicitly wants to ship everything from this worktree without touching the primary worktree.

Let the user pick.

## Report

Report the final commit SHA and confirm `main` is up to date on origin.
