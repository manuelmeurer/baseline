# frozen_string_literal: true

module Baseline
  module ActsAsNotification
    extend ActiveSupport::Concern

    included do
      include HasTimestamps[:read_at]

      belongs_to :notifiable, polymorphic: true, optional: true

      validates :title, presence: true
      validates :important, inclusion: [true, false]

      attribute :important, default: false
    end

    def to_s
      %(Notification "#{title}")
    end
  end
end
