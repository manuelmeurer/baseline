# frozen_string_literal: true

module Baseline
  module Errors
    class Subscriber
      def report(error, handled:, severity:, context:, source:)
        return unless Baseline::Errors.enabled?
        return if severity == :info

        Baseline::Errors::Issue.transaction do
          issue = Baseline::Errors::Issue.find_or_initialize_by(
            fingerprint: Baseline::Errors::Fingerprint.for(error)
          )
          now = Time.current

          issue.assign_attributes(
            class_name:        error.class.name,
            message:           Baseline::Errors.normalize_error_message(error.message),
            backtrace:         Baseline::Errors.normalize_backtrace(error.backtrace),
            causes:            Baseline::Errors::CauseChain.walk(error),
            context:           Baseline::Errors.normalize_context(context.merge(source:, handled:, severity:)),
            last_seen_at:      now,
            resolved_at:       nil,
            occurrences_count: issue.occurrences_count.to_i + 1
          )
          issue.first_seen_at ||= now
          issue.save!
        end
      rescue => subscriber_error
        Rails.logger.error(
          "[Baseline::Errors] subscriber failed: #{subscriber_error.class}: #{subscriber_error.message}"
        )
      end
    end
  end
end
