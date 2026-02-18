---
name: rails-style-guide
description: Rails code style conventions. Use when working with Rails projects, running commands, or writing Rails code.
---

# Rails Style Guide

Apply these conventions when working with Rails projects.

## Guidelines

- In HAML, put Ruby expressions on their own line; avoid inline `=`.

## Binstubs

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

## Namespaces

Treat each Rails app as divided into namespaces. Common ones are `web` (the marketing website), `admin` (the admin area), and `users` (the login area for users).

For each namespace:
- Routes live in `config/routes/NAMESPACE.rb`
- Views live in `app/views/NAMESPACE`
- Controllers live in `app/controllers/NAMESPACE`
- Styles live in `app/assets/stylesheets/NAMESPACE.scss`
- JavaScript lives in `app/javascripts/NAMESPACE.js`
- I18n locale files live in `config/locales/NAMESPACE.LOCALE.yml`

Never create a new namespace unless the user explicitly prompts it. If you are unsure which namespace a change belongs to, ask the user.

## Callbacks

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

## Setting datetime/date columns to current time

When setting a datetime or date column to the current time/date, check if the model includes `HasTimestamps[column]`. If so, use the bang method instead of direct assignment:

```ruby
# Bad - direct assignment when HasTimestamps is available
message.update!(sent_at: Time.current)

# Good - use the bang method from HasTimestamps
message.sent!
```
