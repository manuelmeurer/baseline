# frozen_string_literal: true

module Baseline
  module ActsAsTodoistEvent
    extend ActiveSupport::Concern

    included do
      include HasTimestamps[:processed_at]

      validates :kind, presence: true
      validates :event_id, presence: true
      validates :delivery_id, presence: true, uniqueness: true
      validates :data, presence: true
    end

    def to_s
      "Todoist event #{id}"
    end

    def admin_user
      data["initiator"]
        .fetch("email")
        .then {
          AdminUser.with_email(_1).first ||
            AdminUser.with_alternate_emails(_1).first
        }
    end

    def relevant?
      admin_user
        &.todoist_access_token
        &.then { Baseline::External::Todoist.call(_1, :get_project_id) }
        &.then { event_data.fetch("project_id") == _1 }
    end

    def due_on
      event_data
        .fetch("due")
        &.fetch("date")
        &.then {
          Date.parse _1
        }
    end

    def event_data
      data.fetch("event_data")
    end

    def task
      if relevant?
        Task.find_by(todoist_id: event_data.fetch("id"))
      end
    end

    def added_recently?
      event_data
        .fetch("added_at")
        .then { Time.parse _1 }
        .after? 30.seconds.ago
    end
  end
end
