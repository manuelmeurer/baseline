---
name: git
description: Git operations including committing, pushing, branching, rebasing, and other version control tasks. Use when the user asks to commit, push, pull, merge, rebase, create branches, or perform any other git operation.
---

## Committing

When the user says "commit" without further instructions:

1. Run `git diff` and `git diff --cached` to review all changes.
2. If there are untracked files, ask the user whether to include them before staging. Don't include them automatically.
3. Group related changes into logical commits. Don't lump unrelated changes together. Never commit changes to `stuff.*` files. Exclude them from staging.
4. Write commit messages using the "Conventional Commits" format.
5. After all commits are created, show a summary listing each commit's message and changed files.
