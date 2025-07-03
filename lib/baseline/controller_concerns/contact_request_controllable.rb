# frozen_string_literal: true

module Baseline
  module ContactRequestControllable
    def create
      @success_message = params[:success_message]

      if validate_turnstile
        do_create
      else
        SpamRequest.new(type: "contact", params: contact_request_params).save
      end
    end

    private

      def contact_request_params
        params.require(:contact_request).permit(
          :kind,
          :name,
          :email,
          :phone,
          :message,
          details: {}
        ).merge(language: current_language)
      end

      def do_create
        contact_request = ContactRequest.new(contact_request_params)

        begin
          contact_request.save!
        rescue ActiveRecord::RecordInvalid
          ReportError.call "Error creating contact request",
            errors: contact_request.errors.to_hash
          locals = JSON
            .parse(params[:partial_data])
            .symbolize_keys
            .merge(contact_request:)
          render ContactRequestFormComponent.new(contact_request.kind, **locals),
            status: :unprocessable_entity
          return
        end

        if respond_to?(:after_create, true)
          after_create contact_request
        end

        contact_request_message = contact_request
          .messages
          .created
          .build \
            language: current_language

        Messages::CreateAndSend.call contact_request_message

        Tasks::Create.call \
          taskable:   contact_request,
          priority:   :high,
          title:      "Contact Request bearbeiten",
          details:    "#{contact_request.name} (#{contact_request.email}) hat gerade einen #{contact_request.kind.humanize} Contact Request erstellt.",
          identifier: "handle"
      end
  end
end
