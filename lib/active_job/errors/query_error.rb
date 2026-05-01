# frozen_string_literal: true

module ActiveJob
  module Errors
    QueryError = Baseline::Jobs::Errors::QueryError unless const_defined?(:QueryError, false)
  end
end
