# frozen_string_literal: true

module Baseline
  module ActsAsTodoistEvent
    extend ActiveSupport::Concern

    included do
      include HasTimestamps[:processed_at]

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
          find_admin_user _1
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
