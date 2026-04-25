# frozen_string_literal: true

module Baseline
  module APICalendarControllable
    extend ActiveSupport::Concern

    included do
      before_action do
        @record = SignedGlobalID.find!(params[:record_id])
      rescue ActiveRecord::RecordNotFound
        raise self.class::Error.new(
          "Calendar not found.",
          status: :not_found
        )
      end
    end

    def show
      user          = params[:user_id].then { User.find_signed!(_1) unless _1 == "0" }
      calendar_type = params[:calendar_type].to_sym

      case calendar_type
      when :ics
        ical = @record.service_namespace::GenerateIcal.call(
          @record,
          user:
        )
        render ics: ical
      else
        url = @record.service_namespace::GenerateAddToCalendarURL.call(
          @record,
          calendar_type,
          user:
        )
        redirect_to \
          url,
          allow_other_host: true
      end
    end
  end
end
