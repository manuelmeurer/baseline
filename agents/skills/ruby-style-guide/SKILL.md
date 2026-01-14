---
name: ruby-style-guide
description: Ruby code style conventions. Use when writing, reviewing, or refactoring Ruby code.
---

# Ruby Style Guide

Apply these conventions when writing or modifying Ruby code.

## Strings

**Prefer double quotes** for strings. Use single quotes only when necessary:
- When the string contains double quotes: `'He said "hello"'`
- In shell commands with interpolation: `system('echo "#{variable}"')`
- When following existing code patterns that heavily use single quotes

```ruby
# Good
name = "John"
message = "Hello, #{name}"

# Avoid
name = 'John'
```

## Parallel Assignment

**Use parallel assignment for instance variables** when initializing two or more from local variables with matching names:

```ruby
# Good - 2 variables
def initialize(foo, bar)
  @foo, @bar = foo, bar
end

# Good - 3+ variables split across lines
def initialize(foo, bar, baz)
  @foo, @bar, @baz =
    foo, bar, baz
end

# Avoid
def initialize(foo, bar)
  @foo = foo
  @bar = bar
end
```

## Private Method Indentation

**Indent private methods** by 2 additional spaces after the `private` keyword:

```ruby
class Example
  def public_method
    # code
  end

  private

    def private_method
      # code
    end

    def another_private_method
      # code
    end
end
```

## Conditionals

**Prefer `case when` over `if elsif`** for multiple conditional branches:

```ruby
# Good
case
when condition_a
  do_a
when condition_b
  do_b
else
  do_default
end

# Avoid
if condition_a
  do_a
elsif condition_b
  do_b
else
  do_default
end
```

**Put `if` and `unless` on a separate line.** The only exception is when using `return` or `raise`:

```ruby
# Good
if user.active?
  notify_user
end

return unless success
return if user.banned?

raise if error
raise unless all_good

# Avoid
notify_user if user.active?
save unless dry_run?
```

## Guard Clauses

**Use guard clauses** for early returns:

```ruby
# Good
def process(user)
  return unless user.active?
  return if user.banned?

  # main logic
end

# Avoid
def process(user)
  if user.active? && !user.banned?
    # main logic
  end
end
```

## Safe Navigation

**Use safe navigation operator** for nil checks:

```ruby
# Good
user&.profile&.avatar_url

# Avoid
user && user.profile && user.profile.avatar_url
```

## Block Spacing

**Add a blank line after multi-line block headers** before the block body for readability:

```ruby
# Good
Dir
  .children(root)
  .each do |entry|

  full_path = File.join(root, entry)
end

# Avoid
Dir
  .children(root)
  .each do |entry|
  full_path = File.join(root, entry)
end
```

## Method Chaining

**Use multi-line, leading-dot chaining** when calling more than one method in a row:

```ruby
# Good
Dir
  .children(root)
  .sort
  .select { ... }

# Avoid
Dir.children(root).sort.select { ... }
```

## Prefer Chaining Over Temporary Variables

**Chain methods instead of assigning intermediate variables** when it stays readable:

```ruby
# Good
names =
  users
    .active
    .order(:last_name)
    .pluck(:last_name)

# Avoid
active_users = users.active
ordered_users = active_users.order(:last_name)
names = ordered_users.pluck(:last_name)
```

## Block Parameters

**Prefer numbered parameters for small blocks** to keep them concise:

```ruby
# Good
[1, 2, 3].map { _1 + 3 }

# Avoid
[1, 2, 3].map { |number| number + 3 }
```

## Endless Methods

**Prefer endless method definitions** for simple, single-expression methods:

```ruby
# Good
def add(a, b) = a + b
def magic_word = "please"
def awesome? = true

# Avoid
def add(a, b)
  a + b
end
```
