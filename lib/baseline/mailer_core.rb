# frozen_string_literal: true

module Baseline
  module MailerCore
    extend ActiveSupport::Concern

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
  end
end
