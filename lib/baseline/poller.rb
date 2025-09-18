# frozen_string_literal: true

# Based on https://github.com/octokit/octopoller.rb
module Baseline
  module Poller
    TimeoutError         = Class.new(StandardError)
    TooManyAttemptsError = Class.new(StandardError)

    extend self

    def poll(wait: 1, timeout: nil, retries: nil, errors: [])
      if [nil, false].include?(wait)
        wait = 0
      end
      errors = Array(errors)

      validate_arguments(wait, timeout, retries, errors)

      exponential_backoff = wait == :exponentially
      error = nil
      wait = 0.25 if exponential_backoff

      if timeout
        start = Time.current
        while Time.current < start + timeout
          begin
            block_value = yield
          rescue *errors => error
            block_value = :re_poll
          end
          return block_value unless block_value == :re_poll
          sleep wait
          wait *= 2 if exponential_backoff
        end
        raise TimeoutError.new("Polling timed out patiently"), cause: error
      else
        (retries + 1).times do
          begin
            block_value = yield
          rescue *errors => error
            block_value = :re_poll
          end
          return block_value unless block_value == :re_poll
          sleep wait
          wait *= 2 if exponential_backoff
        end
        raise TooManyAttemptsError.new("Polled maximum number of attempts"), cause: error
      end
    end

    def validate_arguments(wait, timeout, retries, errors)
      if (timeout.nil? && retries.nil?) || (timeout && retries)
        raise ArgumentError, "Must pass an argument to either `timeout` or `retries`"
      end
      exponential_backoff = wait == :exponentially
      raise ArgumentError, "Cannot wait backwards in time" if !exponential_backoff && wait.negative?
      raise ArgumentError, "Timed out without even being able to try" if timeout&.negative?
      raise ArgumentError, "Cannot retry something a negative number of times" if retries&.negative?
      unless errors.all? { _1.is_a?(Class) && _1 < StandardError }
        raise ArgumentError, "Errors must be classes that inherit from StandardError"
      end
    end
  end
end
