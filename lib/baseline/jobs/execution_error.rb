# frozen_string_literal: true

Baseline::Jobs::ExecutionError = Struct.new(:error_class, :message, :backtrace, keyword_init: true) do
  def to_s
    "ERROR #{error_class}: #{message}\n#{backtrace&.collect { "\t#{_1}" }&.join("\n")}"
  end
end
