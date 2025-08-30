# frozen_string_literal: true

module Baseline
  module Rakefile
    extend ActiveSupport::Concern

    included do
      if Gem.loaded_specs["avo"]&.then { _1.source.is_a?(Bundler::Source::Git) }
        Rake::Task["assets:precompile"].enhance do
          Rake::Task["avo:build-assets"].execute
        end
      end

      if Gem.loaded_specs.key?("annotaterb")
        require "annotate_rb"
        AnnotateRb::Core.load_rake_tasks
      end
    end
  end
end
