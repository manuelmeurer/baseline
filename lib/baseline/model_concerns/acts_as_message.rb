# frozen_string_literal: true

module Baseline
  module ActsAsMessage
    extend ActiveSupport::Concern

    included do
      include HasMessageable,
              TouchAsync[:recipient, :messageable, :group]

      belongs_to :recipient, polymorphic: true
      belongs_to :group, class_name: "MessageGroup", foreign_key: :message_group_id, optional: true

      validates :kind, presence: true, inclusion: { in: -> { [_1.group.kind] }, if: :group }
      validates :messageable, inclusion: { in: -> { [_1.group.messageable] }, if: :group }
      validates :recipient_type, inclusion: { in: -> { [_1.class.to_s.delete_suffix("Message")] } }
    end

    def to_s
      "#{kind&.humanize || "Unknown"} message to #{recipient || "?"} (#{sent? ? "sent on #{I18n.l sent_at}" : "unsent"})"
    end
  end
end
