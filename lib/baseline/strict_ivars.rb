# frozen_string_literal: true

require "strict_ivars"

root = Dir.pwd
StrictIvars.init(
  include: [File.join(root, "**", "*")],
  exclude: %w[vendor .bundle].map { File.join(root, _1, "**", "*") }
)
