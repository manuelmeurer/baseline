# frozen_string_literal: true

module Baseline
  module Errors
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true

      if Baseline::Errors.db_config_present?
        connects_to database: { writing: :errors, reading: :errors }
      end
    end
  end
end
