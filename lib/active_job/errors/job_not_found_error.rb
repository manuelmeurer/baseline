# frozen_string_literal: true

module ActiveJob
  module Errors
    JobNotFoundError = Baseline::Jobs::Errors::JobNotFound unless const_defined?(:JobNotFoundError, false)
  end
end
