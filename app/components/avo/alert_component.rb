# frozen_string_literal: true

# Override Avo's AlertComponent to apply simple_format to flash messages.
# We need to re-implement the full class because ViewComponent requires the class
# file to exist alongside the template for proper template resolution.

# Verify original implementation hasn't changed from version 3.28.0, when this override was created.
Baseline::VerifyGemFileSource.call(
  "avo",
  "app/components/avo/alert_component.rb",
  "d0ced23ff53e9619d85319e1d61ffc59a9560992461aa3dae5f2f1205d357d78"
)

class Avo::AlertComponent < Avo::BaseComponent
  include Avo::ApplicationHelper

  prop :type, kind: :positional
  prop :message, kind: :positional
  prop :timeout

  def icon
    return "heroicons/solid/exclamation-circle" if is_error?
    return "heroicons/solid/exclamation" if is_warning?
    return "heroicons/solid/exclamation-circle" if is_info?
    return "heroicons/solid/check-circle" if is_success?

    "check-circle"
  end

  def classes
    return "hidden" if is_empty?

    result = "max-w-lg w-full shadow-lg rounded px-4 py-3 rounded relative border text-white pointer-events-auto"

    result += if is_error?
      " bg-red-400 border-red-600"
    elsif is_success?
      " bg-green-500 border-green-600"
    elsif is_warning?
      " bg-orange-400 border-orange-600"
    else
      " bg-blue-400 border-blue-600"
    end

    result
  end

  def is_error?
    @type.to_sym == :error || @type.to_sym == :alert
  end

  def is_success?
    @type.to_sym == :success
  end

  def is_info?
    @type.to_sym == :notice || @type.to_sym == :info
  end

  def is_warning?
    @type.to_sym == :warning
  end

  def is_empty?
    @message.nil?
  end

  def timeout
    return @timeout if @timeout.is_a?(Numeric)
    Avo.configuration.alert_dismiss_time
  end

  def keep_open?
    @timeout.try(:to_sym) == :forever
  end
end
