# frozen_string_literal: true

module Baseline
  module ContactRequestControllable
    def create
      unless validate_turnstile
        SpamRequest.create \
          kind: :contact,
          data: contact_request_params
        return
      end

      do_create

      @success_message = params[:success_message]

      respond_to do |format|
        format.turbo_stream do
          if defined?(@error_message)
            render_turbo_response \
              error_message: @error_message
          else
            render "baseline/contact_requests/create"
          end
        end
      end
    end

    private

      def contact_request_params
        params.require(:contact_request).permit(
          :company,
          :email,
          :kind,
          :message,
          :name,
          :phone,
          details: {}
        ).merge(language: current_language)
      end

      def do_create
        contact_request = ContactRequest.new(
          locale: I18n.locale,
          **contact_request_params
        )

        begin
          contact_request.save!
        rescue ActiveRecord::RecordInvalid
          ReportError.call "Error creating contact request",
            errors: contact_request.errors.to_hash
          @error_message = contact_request.errors.full_messages.to_sentence
          return
        end

        if respond_to?(:after_create, true)
          after_create contact_request
        end

        contact_request
          .messages
          .created
          .build
          ._do_create_and_send

        Tasks::Create.call \
          taskable:   contact_request,
          priority:   :high,
          title:      "Contact Request bearbeiten",
          details:    "#{contact_request.name} (#{contact_request.email}) hat gerade einen #{contact_request.kind.humanize} Contact Request erstellt.",
          identifier: "handle"
      end
  end
end
