# frozen_string_literal: true

require "digest/sha1"

module Baseline
  module Errors
    module Fingerprint
      class << self
        def for(error)
          Digest::SHA1.hexdigest([error.class.name, top_frame(error)].join("\n"))
        end

        private

          def top_frame(error)
            Baseline::Errors
              .normalize_backtrace(error.backtrace)
              .detect { _1.include?(Rails.root.to_s) } ||
              Baseline::Errors.normalize_backtrace(error.backtrace).first ||
              error.class.name
          end
      end
    end
  end
end
