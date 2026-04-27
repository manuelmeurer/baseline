# frozen_string_literal: true

module Baseline
  module Errors
    class ErrorContextMiddleware
      def call(_error, context:, **)
        context = context.symbolize_keys

        controller = context.delete(:controller)
        request    = controller&.request

        normalized = {
          request_method:      request&.request_method || context[:request_method],
          filtered_path:       request&.filtered_path || context[:filtered_path],
          filtered_parameters: request&.filtered_parameters || context[:filtered_parameters],
          user_agent:          request&.user_agent || context[:user_agent],
          request_id:          request&.request_id || context[:request_id],
          remote_ip:           request&.remote_ip || context[:remote_ip],
          host:                request&.host || context[:host],
          controller_name:     controller&.class&.name,
          action_name:         controller&.action_name || ::Current.try(:action_name),
          namespace:           ::Current.try(:namespace),
          current_user_id:     current_user_id,
          rails_env:           Rails.env,
          hostname:            Socket.gethostname
        }.compact

        context
          .except(:headers, :params, :request, :response)
          .merge(normalized)
          .then { Baseline::Errors.normalize_context(_1) }
      end

      private

        def current_user_id
          ::Current.try(:user)&.id || ::Current.try(:admin_user)&.id
        end
    end
  end
end
