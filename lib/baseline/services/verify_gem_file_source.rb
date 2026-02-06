# frozen_string_literal: true

module Baseline
  class VerifyGemFileSource < BaseService
    # Raises if a gem file's SHA256 digest doesn't match the expected value.
    def call(gem_name, file_path, expected_sha256)
      return unless spec = Gem.loaded_specs[gem_name]

      require "digest"

      original = File.join(spec.full_gem_path, file_path)
      actual   = Digest::SHA256.file(original).hexdigest

      unless actual == expected_sha256
        raise "#{gem_name} source changed for #{file_path} (expected #{expected_sha256}, got #{actual})"
      end
    end
  end
end
