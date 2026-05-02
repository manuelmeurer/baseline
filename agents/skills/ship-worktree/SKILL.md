---
name: ship-worktree
description: Commit current worktree changes and fast-forward merge into the worktree's base branch. Use when the user asks to finish a feature in a git worktree by committing and merging into its base or landing branch, or simply says "ship" while the app is in a git worktree.
---

# Ship Worktree

You are finishing a feature in a git worktree.

**Goal:** land this worktree's commits on its landing branch (locally and on `origin`). The worktree branch itself is throwaway - never push the worktree branch ref to `origin`. Only the landing branch gets published. After shipping, the worktree branch exists only locally and can be deleted.

Do the following:

1. Run `git status --short` to show current status.
2. Run `git diff --stat HEAD` to show the diff summary.
3. Run `git log --oneline -5` to show recent commits on this branch.

## Commit

- If the user passed a commit message as an argument, stage everything and combine all changes into a single commit using that message.
- Otherwise, group related changes into logical commits - do not lump unrelated changes together in one commit. Write commit messages using the "Conventional Commits" format.

## Hard rules

- **Never use `git update-ref` to advance the landing branch.** It bypasses Git's safety net and silently desyncs the index/working tree of any worktree that has the landing branch checked out (you'll see phantom "deleted" / "modified" entries in `git status` there). If `git push . HEAD:$landing_branch` is rejected because the landing branch is checked out elsewhere, do NOT reach for `update-ref` - push `HEAD` directly to `origin/$landing_branch` and have the primary worktree pull with `git pull --ff-only`.
- Never ask the user to detach `HEAD` in another worktree.
- Never `push --force` and never push the worktree branch ref to `origin`. Only the landing branch gets published.

## Determine landing branch

Before syncing, determine the branch this worktree should land on. Do not assume it is `main`.

Use this source order:

1. If the user explicitly named a target branch, use it.
2. Otherwise, use `branch.<current_branch>.base` from Git config. This is the best automatic source because Superset worktrees record the branch they were created from there.
3. Otherwise, if the current branch has an upstream whose branch name differs from the current branch, use that upstream's branch name after stripping the remote prefix.

Normalize the result to a local branch name like `release/1.2`, not `origin/release/1.2` or `refs/heads/release/1.2`.

Run:

```sh
current_branch="$(git branch --show-current)"
git config --get "branch.${current_branch}.base"
git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true
```

Set:

```sh
landing_branch="..."
origin_landing_branch="origin/${landing_branch}"
```

Reject the candidate immediately if it matches the current worktree branch:

```sh
test "$landing_branch" != "$current_branch"
```

If no candidate passes this check, stop and ask the user which branch to land on. Do not fall back to `main` just because it exists.

## Sync with origin

Run `git fetch origin`, then validate the local and origin landing branch refs:

```sh
git rev-parse --verify "refs/heads/$landing_branch"
git rev-parse --verify "refs/remotes/origin/$landing_branch"
```

Then determine the state of the three relevant refs: `HEAD`, local landing branch, and origin landing branch.

```sh
git rev-parse HEAD
git rev-parse "$landing_branch"
git rev-parse "$origin_landing_branch"
git merge-base --is-ancestor "$landing_branch" "$origin_landing_branch" && echo "local landing branch is ancestor of origin landing branch (no unpushed local landing branch commits)" || echo "local landing branch has commits not on origin landing branch"
git merge-base --is-ancestor "$origin_landing_branch" HEAD && echo "origin landing branch is reachable from HEAD (HEAD contains everything on origin landing branch)" || echo "origin landing branch has commits not in HEAD (HEAD is behind or diverged)"
```

The second check tells you whether the origin landing branch is an ancestor of `HEAD`, not whether `HEAD` is strictly behind. A "not reachable" result can mean either (a) `HEAD` is strictly behind the origin landing branch, or (b) `HEAD` and the origin landing branch have diverged. To disambiguate, also list commits in both directions:

```sh
git log --oneline "$origin_landing_branch"..HEAD   # commits on this branch not yet on origin landing branch
git log --oneline HEAD.."$origin_landing_branch"   # commits on origin landing branch not yet on this branch
```

If both lists are non-empty, the branches have diverged - treat that as Case B (rebase) unless the divergence is unexpected.

### Case A: clean fast-forward possible

Local landing branch is an ancestor of the origin landing branch, and the origin landing branch is an ancestor of `HEAD`. Fast-forward local landing branch to `HEAD`, then push the landing branch (not the worktree branch) to `origin`:

```sh
git push . "HEAD:$landing_branch"
git push origin "$landing_branch"
```

If `git push . "HEAD:$landing_branch"` is rejected with `refusing to update checked out branch`, that means the landing branch is checked out in another worktree (typically the primary one). Do NOT use `git update-ref` to work around it, and do NOT ask the user to detach `HEAD` in the other worktree. Instead, push directly to the origin landing branch from here and let the primary worktree fast-forward via `git pull --ff-only`:

```sh
git push origin "HEAD:$landing_branch"
```

### Case B: branch is behind origin landing branch (easy case - handle automatically)

Local landing branch is an ancestor of (or equal to) the origin landing branch, but the origin landing branch is NOT an ancestor of `HEAD`. This means the origin landing branch has moved forward since this branch was created, but the local landing branch has no unpushed commits.

Rebase this branch onto the origin landing branch, fast-forward local landing branch to `HEAD`, then push the landing branch (not the worktree branch) to `origin`:

```sh
git rebase "$origin_landing_branch"
git push . "HEAD:$landing_branch"
git push origin "$landing_branch"
```

If `git push . "HEAD:$landing_branch"` is rejected because the landing branch is checked out elsewhere, use the Case A fallback and push directly to `origin`.

If the rebase has conflicts, stop and report.

### Case C: local landing branch has unpushed commits not in this branch (confirm with user)

Local landing branch is NOT an ancestor of the origin landing branch - local landing branch has commits that haven't been pushed and aren't in this branch. A safe fast-forward of local landing branch from this worktree is not possible without first publishing those commits.

Stop. Do NOT force-push. Do NOT auto-rebase. Do NOT cherry-pick.

Show the user the three SHAs (`HEAD`, local landing branch, origin landing branch) and the commits unique to local landing branch. The only thing to confirm is whether those local landing branch commits are **ready to publish to the origin landing branch now** (they might be WIP, not reviewed, etc.).

If yes, do this automatically - no further questions:

```sh
git push origin "$landing_branch:$landing_branch" # publish local landing branch's unpushed commits
git pull --rebase origin "$landing_branch"        # rebase this branch on top
```

Then proceed with Case A.

If the user says no (local landing branch commits aren't ready), stop and let them sort it out before retrying.

## Report

Report the final commit SHA and confirm the landing branch is up to date on origin.
