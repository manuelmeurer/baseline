# frozen_string_literal: true

module ActiveJob
  module Errors
    InvalidOperation = Baseline::Jobs::Errors::InvalidOperation unless const_defined?(:InvalidOperation, false)
  end
end
