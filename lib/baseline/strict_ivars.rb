# frozen_string_literal: true

require "strict_ivars"
require "require-hooks/api"

# Scopes the RequireHooks source_transform to app files only, instead of the
# default `**/*` used by `StrictIvars.init`. Skipping gem paths avoids the
# per-require `context_for` lookup and parser overhead, saving ~4% of boot
# time.
#
# Tradeoff: the canonical `StrictIvars.init` also runs `BaseProcessor` on
# non-app files, which rewrites `eval`/`class_eval`/`module_eval`/
# `instance_eval` call sites in gems so their string arguments get processed
# at eval time. Scoping the hook to app paths skips that rewriting for gem
# files. Runtime eval routing via `StrictIvars::CONFIG.match?` still works
# for evals originating in app code.
root = Dir.pwd
include_patterns = [File.join(root, "**", "*")]
exclude_patterns = %w[vendor .bundle].map { File.join(root, _1, "**", "*") }

StrictIvars::CONFIG.include(*include_patterns)
StrictIvars::CONFIG.exclude(*exclude_patterns)

RequireHooks.source_transform(
  patterns:         include_patterns,
  exclude_patterns: exclude_patterns
) do |path, source|
  StrictIvars::Processor.call(source || File.read(path))
end
