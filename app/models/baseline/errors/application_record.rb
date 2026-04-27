# frozen_string_literal: true

module Baseline
  module Errors
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true

      if Baseline::Errors.db_config_present?
        connects_to database: { writing: :errors, reading: :errors }
      end

      class << self
        def connection
          return super if @ensuring_errors_schema

          @ensuring_errors_schema = true
          Baseline::Errors.ensure_schema!
          super
        ensure
          @ensuring_errors_schema = false
        end
      end
    end
  end
end
