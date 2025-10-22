# frozen_string_literal: true

module Baseline
  module UserProxy
    extend ActiveSupport::Concern

    FIELDS  = %i[first_name last_name email gender locale language].freeze
    METHODS = [*FIELDS, :name].flat_map { [_1, "#{_1}="] }.freeze

    included do
      delegate \
        :to_s, :login_token,
        *METHODS,
        *User.genders.keys.map { "#{_1}?" },
        to: :user

      FIELDS.each do |attribute|
        scope :"with_#{attribute}", ->(value) {
          with_user User.where(attribute => value)
        }
      end

      def self.method_missing(method, ...)
        with_first_name(method.capitalize).first or
          super
      end
    end
  end
end
