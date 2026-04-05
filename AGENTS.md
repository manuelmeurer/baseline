# AGENTS.md

## Guidelines

- Work style: telegraph; noun-phrases ok; drop grammar; min tokens.
- Default language: Ruby. Prefer Ruby when writing scripts.
- To delete files or folders, always use `trash` instead of `rm`.

## Project shorthand

Note: use these names in conversation (e.g., "copy the file from uplink" or "check out funlocked for an example"); list maps shorthand to source code locations.

- baseline: ~/code/own/baseline
- dasauge: ~/code/own/dasauge/app
- dotfiles: ~/code/own/dotfiles
- funlocked: ~/code/own/funlocked/app
- notetoself: ~/code/own/notetoself
- rubydocs: ~/code/own/rubydocs/app
- spendex: ~/code/own/spendex
- tasks: ~/code/own/tasks
- uplink: ~/code/own/uplink/app
- m4l: ~/code/own/m4l

## Ruby Style Guide

Apply these conventions when writing or modifying Ruby code.

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

## Rails Style Guide

Apply these conventions when working with Rails projects.

- In HAML, put Ruby expressions on their own line; avoid inline `=`.

### Binstubs

When running Rails executables, **always check for binstubs first**:

1. **Check for binstub**: Look for `bin/rails`, `bin/rspec`, `bin/rubocop`, etc.
2. **Use binstub if exists**: Run `bin/rails` instead of `bundle exec rails`
3. **Fallback to bundle exec**: Only use `bundle exec` if no binstub exists

```bash
# Good - check for binstub first
bin/rails db:migrate
bin/rspec spec/models/user_spec.rb

# Only if binstubs don't exist
bundle exec rails db:migrate
bundle exec rspec spec/models/user_spec.rb
```

**When bundle exec fails**: Inform the user that a binstub might resolve the issue, as binstubs can have different load paths or configurations.

### Namespaces

Treat each Rails app as divided into namespaces. Common ones are `web` (the marketing website), `admin` (the admin area), and `users` (the login area for users).

For each namespace:
- Routes live in `config/routes/NAMESPACE.rb`
- Views live in `app/views/NAMESPACE`
- Controllers live in `app/controllers/NAMESPACE`
- Styles live in `app/assets/stylesheets/NAMESPACE.scss`
- JavaScript lives in `app/javascripts/NAMESPACE.js`
- I18n locale files live in `config/locales/NAMESPACE.LOCALE.yml`

Never create a new namespace unless the user explicitly prompts it. If you are unsure which namespace a change belongs to, ask the user.

### Callbacks

Prefer block-style callbacks over defining a separate method:

```ruby
# Good - block style
before_validation do
  self.slug = name&.parameterize
end

after_create do
  notify_admins
  schedule_welcome_email
end

# Bad - separate method for simple logic
before_validation :set_slug

private

def set_slug
  self.slug = name&.parameterize
end
```

Exceptions where a separate method makes sense:
- The callback logic is very complex (20+ lines)
- Several callbacks execute the same logic

```ruby
# OK - complex logic in a separate method
after_create :sync_to_external_services

# OK - same logic reused by multiple callbacks
after_create :recalculate_totals
after_destroy :recalculate_totals
```

### Setting datetime/date columns to current time

When setting a datetime or date column to the current time/date, check if the model includes `HasTimestamps[column]`. If so, use the bang method instead of direct assignment:

```ruby
# Bad - direct assignment when HasTimestamps is available
message.update!(sent_at: Time.current)

# Good - use the bang method from HasTimestamps
message.sent!
```

## JavaScript Style Guide

Apply these conventions when writing or modifying JavaScript code.

- Always put the body of an `if` statement on a separate line, even for simple returns.
