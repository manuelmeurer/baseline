# frozen_string_literal: true

module Baseline
  module ActsAsMessageGroup
    extend ActiveSupport::Concern

    included do
      include Baseline::HasLocale,
              Baseline::HasSections,
              HasTimestamps[:sending_started_at]

      belongs_to :messageable, polymorphic: true

      has_many :messages, dependent: :destroy

      validates :kind, presence: true, inclusion: { in: :valid_kinds, allow_nil: true }

      validate on: :send_live do
        case
        when recipients.none? then errors.add :base,     message: "No recipients found."
        when messages.any?    then errors.add :messages, message: "already exist"
        end
      end

      # Use a custom validator instead of the "inclusion" validator
      # since for STI, "messageable_type" will save the parent class,
      # but we want to use the child classes in valid_kinds.
      validate if: :messageable do
        unless self.class.valid_kinds.keys.flatten.include?(messageable.class)
          errors.add :messageable
        end
      end

      valid_kinds.values.flatten.each do |kind|
        scope kind, -> { where(kind:) }
        define_method "#{kind}?" do
          self.kind == kind
        end
      end
    end

    def to_s  = "#{kind&.humanize || "Unknown"} message group for #{messageable}"
    def sent? = sending_started? && recipients.none?

    def valid_kinds
      unless messageable
        raise "Cannot determine valid kinds without messageable."
      end

      self
        .class
        .valid_kinds
        .detect { Array(_1.first).include?(messageable.class) }
        &.last or
          raise "Unexpected messageable class: #{messageable.class}"
    end

    def message_class
      "#{recipients.klass}Message".constantize
    end

    def valid_delivery_methods = %i[email]

    def assign_parts_from_i18n
      return unless messageable && kind && locale

      Messages::GeneratePartsFromI18n
        .call(self)
        .then {
          assign_attributes _1
        }
    end

    def recipient_users
      User
        .active
        .where(locale:)
        .email_confirmed
        .created_before(sending_started_at || Time.current)
    end

    def find_or_initialize_message_for_preview(delivery_method)
      unless delivery_method.to_sym.in?(valid_delivery_methods)
        raise "#{delivery_method} is not a valid delivery method for this message group."
      end

      messages
        .public_send(:"with_#{delivery_method}_delivery")
        .first ||
      recipients
        .first
        &.then {
          _do_initialize_message(_1, delivery_method:)
        }
    end
  end
end
