# frozen_string_literal: true

module Baseline
  module MailerPreviewCore
    extend ActiveSupport::Concern

    class_methods do
      def generate_message_descendant_methods
        Message.descendants.each do |klass|
          klass
            .kinds
            .each_key do |kind|

            define_method "#{klass.to_s.underscore}_#{kind}" do
              message = klass
                .where(kind:)
                .order(id: :desc)
                .lazy
                .detect { _1.locale_without_region.to_sym == locale }

              unless message
                raise "Cannot find #{klass} with kind #{kind} and locale #{locale}."
              end

              ApplicationMailer.email_delivery(message.email_delivery)
            end
          end
        end
      end
    end

    private def locale = params[:locale]&.to_sym || I18n.default_locale
  end
end
