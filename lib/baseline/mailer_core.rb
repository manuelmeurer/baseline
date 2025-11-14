# frozen_string_literal: true

module Baseline
  module MailerCore
    def self.[](from_name:)
      Module.new do
        extend ActiveSupport::Concern

        included do
          default from: "#{from_name} <#{Rails.application.env_credentials.mail_from!}>"

          layout "mailers/default"

          # Include ApplicationHelper and MailerHelper from app.
          helper :application

          suppress NameError do
            helper :mailer
          end

          # Include MailerHelper from Baseline.
          helper MailerHelper

          after_action :deliver_via_postmark,
            if: -> { defined?(@email_delivery) && @email_delivery.postmark_message_stream }
        end

        class_methods do
          def inherited(subclass)
            identifier = subclass
              .to_s
              .underscore
              .delete_suffix("_mailer")

            subclass.layout "mailers/#{identifier}"

            subclass.default template_path: "mailers/#{identifier}"

            suppress NameError do
              subclass.helper subclass.to_s
            end
          end
        end

        def email_delivery(email_delivery, preview = false) # kwargs are not supported here.
          @email_delivery = email_delivery
          @admin_user     = email_delivery.admin_user
          @sections       = email_delivery.sections.to_a
          @messageable    = email_delivery.deliverable.try(:messageable)

          @messageable
            .try(:survey_connections)
            .to_a
            .sort_by { -_1.position }
            .each do |survey_connection|

            @sections.insert \
              survey_connection.position - 1,
              *survey_connection.survey.sections
          end

          email_delivery.attached_files.each do |filename, file_generator|
            unless mime_type = Marcel::MimeType.for(filename)
              raise "Could not determine content type for #{filename}"
            end

            content =
              preview ?
              "" :
              file_generator.call.read

            attachments[filename] = {
              content:,
              mime_type:
            }
          end

          if unsubscribe_params = email_delivery.unsubscribe_params
            unsubscribe_params[:sgid] = unsubscribe_params
              .delete(:user)
              .to_sgid
              .to_s
            unsubscribe_urls = [
              url_for([:api, :unsubscribe, unsubscribe_params]),
              Addressable::URI.new(
                scheme: "mailto",
                path:   Rails.application.env_credentials.mail_from!,
                query_values: {
                  subject: "unsubscribe",
                  body:    unsubscribe_params.to_json
                }
              ).to_s
            ]
            headers \
              "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
              "List-Unsubscribe":      unsubscribe_urls.map { "<#{_1}>" }.join(", ")
          end

          params = {
            to:       mail_addresses(email_delivery.recipients),
            cc:       mail_addresses(email_delivery.cc_recipients),
            bcc:      mail_addresses(email_delivery.bcc_recipients),
            subject:  email_delivery.subject,
            reply_to: email_delivery.reply_to
          }
          if @admin_user
            params[:from] = mail_address(@admin_user)
          end
          if message_stream = email_delivery.postmark_message_stream
            params[:message_stream] = message_stream
          end

          deliverable_template = ["mailers", email_delivery.deliverable.class.to_s.underscore].join("/")
          template =
            lookup_context.exists?(deliverable_template) ?
            deliverable_template :
            "baseline/mailers/email_delivery"

          I18n.with_locale email_delivery.locale do
            @debug_sections = preview

            mail params do |format|
              render_params = {
                layout: @admin_user&.then { "mailers/personal" },
                template:
              }.compact

              format.text { render(**render_params) }
              format.html { render(**render_params) }
            end
          end
        end

        private

          def mail_address(user, email = user.email)
            email_address_with_name \
              email,
              user.try(:name)
          end

          def mail_addresses(recipients)
            recipients.map { mail_address _1, _2 }
          end

          def deliver_via_postmark
            wrap_delivery_behavior! :postmark
          end
      end
    end
  end
end
