# frozen_string_literal: true

module Baseline
  class VerifyGemFileSource < BaseService
    # Raises if a gem file's SHA256 digest doesn't match the expected value.
    #
    #   call("avo", "path/to/file.rb" => "abc123", "path/to/other.erb" => "def456")
    def call(gem_name, files_with_digests)
      return unless spec = Gem.loaded_specs[gem_name]

      require "digest"

      files_with_digests.each do |file_path, expected|
        original = File.join(spec.full_gem_path, file_path)
        actual   = Digest::SHA256.file(original).hexdigest

        unless actual == expected
          raise "#{gem_name} source changed for #{file_path} (expected #{expected}, got #{actual})"
        end
      end
    end
  end
end
