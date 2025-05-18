# frozen_string_literal: true

module Baseline
  module APITodoistControllable
    def event
      unless delivery_id = request.headers["X-Todoist-Delivery-ID"]
        raise "Could not find delivery ID header."
      end

      unless request.user_agent == "Todoist-Webhooks"
        raise "Unexpected user agent: #{request.user_agent}"
      end

      scope = TodoistEvent.where(delivery_id:)
      unless scope.exists?
        scope.create!(
          data:     json_body,
          kind:     json_body.fetch(:event_name),
          event_id: json_body[:event_data].fetch(:id)
        )._do_process(_async: true)
      end

      head :ok
    end
  end
end
