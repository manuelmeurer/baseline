---
name: ship-worktree
description: Commit current worktree changes and fast-forward merge into main. Use when the user asks to finish a feature in a git worktree by committing and merging into main, or simply says "ship" while the app is in a git worktree.
---

# Ship Worktree

You are finishing a feature in a git worktree. Do the following:

1. Run `git status --short` to show current status.
2. Run `git diff --stat HEAD` to show the diff summary.
3. Run `git log --oneline -5` to show recent commits on this branch.

Now:

- Commit the changes:
  - If the user passed a commit message as an argument, stage everything and combine all changes into a single commit using that message.
  - Otherwise, group related changes into logical commits — do not lump unrelated changes together in one commit. Write commit messages using the "Conventional Commits" format.
- Then run:
  - `git fetch origin`
  - `git push . HEAD:main` (fast-forward local main from this worktree)
  - `git push origin main`
- If the fast-forward push fails because main moved, stop and report back — do NOT force-push and do NOT auto-rebase without asking.

Report the final commit SHA and confirm main is up to date on origin.
