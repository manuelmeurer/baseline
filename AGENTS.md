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

## Git

When the user says "git commit" without further instructions:

1. Run `git diff` and `git diff --cached` to review all changes.
2. If there are untracked files, ask the user whether to include them before staging. Don't include them automatically.
3. Group related changes into logical commits. Don't lump unrelated changes together. Never commit changes to `stuff.*` files, unless the user explicitly instructs you to.
4. Write commit messages using the "Conventional Commits" format.
5. After all commits are created, show a summary listing each commit's message and changed files.

## Ruby Style Guide

Apply these conventions when writing or modifying Ruby code.

- Always include `# frozen_string_literal: true` at the top of every Ruby file.
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
- Prefer hash value omission (`{ foo:, bar: }` over `{ foo: foo, bar: bar }`). When a method call with kwargs or a hash literal mixes omitted and non-omitted values, always put the omitted values first.
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

## HAML Style Guide

Apply these conventions when working with HAML.

- Always include `-# frozen_string_literal: true` at the top of every HAML file.
- Put as many classes as possible at the beginning of the tag. Only use the `class` option for classes with characters HAML can't handle (e.g. `/`):
  ```haml
  -# bad
  %div{ class: "class1 class2 class3", id: "myid" }
  .class1.class2{ class: "class3", id: "myid" }

  -# good
  .class1.class2.class3{ id: "myid" }
  .class1.class2.class3{ class: "w-5/12", id: "myid" }
  ```
- Put Ruby expressions on their own line; avoid inline `=`:
  ```haml
  -# bad
  %h1= page_title

  -# good
  %h1
    = page_title
  ```

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

### Partials

Always use [strict locals](https://guides.rubyonrails.org/action_view_overview.html#strict-locals) when creating or modifying Rails partials. Declare the expected locals via a magic comment at the top of the partial:

```haml
-# frozen_string_literal: true
-# locals: (user:, size: :medium)
```

### Forms

- Inspect existing form patterns in the codebase first.
- Always use `form_with` when creating or modifying forms.
- Use the `turbo_data` helper for Turbo-related data attributes.
- For form actions, always use the `form_actions` component.
- Prefer using the `form_field` component with the appropriate field type; for hidden fields, use `hidden_field` instead; use field type `:base` only in rare cases for custom fields not used elsewhere in the codebase.
- Add custom labels, hints, and help texts via I18n using the keys expected by the `form_field` component. Check the component for the expected I18n keys.
- When adding I18n entries, update all locales in use.

### I18n

- Don't use relative lookups with leading dots (`.key`) or chain keys together with dots (`foo.bar.baz`). Instead, always use a symbol as the key and an array of symbols as the scope parameter: `t :baz, scope: %i[foo bar]`. Only deviate from this rule if absolutely necessary.
- Always try to use `action_i18n_scope` or `base_i18n_scope` (in that order) as the scope. Both are defined in `Baseline::I18nScopes`, but might be overwritten in the controller. When inside a section generated with the `section` helper, `section_i18n_scope` might be an even better option.
- Always use `|-` for multi-line strings in I18n files.
- For translated text in views that consists of one or more paragraphs, use the `md_to_html` helper, e.g. `md_to_html t(:text, scope: action_i18n_key)`.
- When moving text from a view to I18n, first determine the language of the text in the view, move each text fragment to the corresponding namespaced I18n file, and then translate each fragment into the other locales used in the namespace and add them to the correct I18n files.
- Don't use automatic safe HTML rendering with the `_html` postfix. Use the explicit `md_to_html` helper instead if the text fragment includes HTML.
- Prefer Markdown links to passing HTML anchor elements to I18n with the `link_to` helper. External links (pointing to a different host than the app) automatically receive `target="_blank"` and the other attributes from the `external_link_attributes` helper.
- Prefer these I18n keys: `headline` for headlines, `text` for the main text of the page or section, `cta` for the text of a call to action (often a button or link). If text needs to be broken up into several I18n keys, use `text_1`, `text_2`, etc. If none of these are a good match, check the locale files for keys that have been previously used for similar text fragments.
- Prefer simple names for interpolation attributes: `name`, `url`, `cta`, etc. When in doubt, check the locale files for interpolation attributes that have been previously used.
- Don't use quotes for I18n values, unless they contain a colon.
- Never include URLs in I18n values; always pass them in as an interpolation variable.

## JavaScript Style Guide

Apply these conventions when writing or modifying JavaScript code.

- Always put the body of an `if` statement on a separate line, even for simple returns.
- Omit curly braces for single-line blocks when JavaScript syntax allows it.
- Omit parentheses around arrow function parameters when possible. Parens are only required for zero params, multiple params, destructured params, rest params, or params with default values / type annotations — a single plain param should be written without parens (`x => x * 2`, not `(x) => x * 2`).
- Don't abbreviate parameters or variables to single letters. Use full names (e.g. `event` for an event listener param, not `e`; `error` instead of `err`; `element` instead of `el`).
