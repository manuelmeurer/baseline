# frozen_string_literal: true

module Baseline
  module Errors
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_files
        template "db/errors_schema.rb"
      end
    end
  end
end
