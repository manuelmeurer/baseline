---
name: ruby-style-guide
description: Ruby code style conventions. Use when writing, reviewing, or refactoring Ruby code. Use when user says "write a Ruby script", "refactor this Ruby", "review this code", or works in .rb files.
---

# Ruby Style Guide

Apply these conventions when writing or modifying Ruby code.

## Guidelines

- When writing a Ruby script or CLI, always use [Thor](https://github.com/rails/thor).
- Prefer double quotes for strings; use single quotes only when the string contains double quotes, in shell commands with interpolation, or when following existing code patterns.
- Use parallel assignment for instance variables when initializing from local variables with matching names; split across two lines when assigning 3 or more.
- Indent private methods by 2 additional spaces after the `private` keyword.
- Prefer `case when` over `if elsif` for multiple conditional branches.
- Put `if` and `unless` on a separate line, except when using `return` or `raise` without arguments or with one short argument: `return if failed?`, `return false if failed?`, `raise unless succeeded?`, `raise error unless succeeded?`
- Use guard clauses for early returns.
- Use safe navigation operator (`&.`) for nil checks.
- Add a blank line before the block body only when the block header consists of multiple lines.
- Use multi-line, leading-dot chaining when calling more than one method in a row.
- Prefer chaining over temporary variables when it stays readable; `then` and `tap` are often helpful.
- Prefer numbered parameters (`_1`, `_2`) for small blocks; use `it` only when numbered params don't work.
- Prefer endless method definitions for simple, single-expression methods that fit within 80 chars.
- Prefer percent notation for arrays of symbols, array of strings, and regexes (`%i[foo bar]` over `[:foo, :bar]`, `%w[foo bar]` over `["foo", "bar"]` and `%r(foo)` over `/foo/`).
- Prefer hash value omission (`{ foo:, bar: }` over `{ foo: foo, bar: bar }`).
- When a method call with keyword arguments or a hash literal exceeds ~80 chars, break after the first argument using a trailing backslash and align remaining args:
  ```ruby
  # bad
  render partial: "webinars/header_image_page", locals: { webinar: requested_resource }, layout: false

  # good
  render \
    partial: "webinars/header_image_page",
    locals:  { webinar: requested_resource },
    layout:  false
  ```
