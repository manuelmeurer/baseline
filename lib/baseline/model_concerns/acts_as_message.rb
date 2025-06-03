# frozen_string_literal: true

module Baseline
  module ActsAsMessage
    extend ActiveSupport::Concern

    included do
      include TouchAsync[:recipient, :messageable, :group]

      belongs_to :recipient, polymorphic: true
      belongs_to :messageable, polymorphic: true, optional: true
      belongs_to :group, class_name: "MessageGroup", foreign_key: :message_group_id, optional: true

      validates :kind, presence: true, inclusion: { in: -> { [_1.group.kind] }, if: :group }
      validates :messageable, inclusion: { in: -> { [_1.group.messageable] }, if: :group }
      validates :recipient_type, inclusion: { in: -> { [_1.class.to_s.delete_suffix("Message")] } }
    end

    class_methods do
      def validate_messageable(kind_messageable_classes)
        validate if: :kind do
          # Keys of `kind_messageable_classes` can be symbols or regexes.
          messageable_class = kind_messageable_classes
            .detect { _1.first === kind.to_sym }
            &.last ||
              NilClass
          unless messageable.is_a?(messageable_class)
            expected, actual = [messageable_class, messageable.class].map { _1.nil? ? "nil" : "a #{_1}" }
            errors.add :messageable, message: "must be #{expected} but is #{actual}"
          end
        end
      end
    end

    def to_s
      "#{kind&.humanize || "Unknown"} message to #{recipient || "?"} (#{sent? ? "sent on #{I18n.l sent_at}" : "unsent"})"
    end
  end
end
