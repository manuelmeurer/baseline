# frozen_string_literal: true

module Baseline
  module Errors
    class RequestContextMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        ActiveSupport::ExecutionContext[:request_method]      = request.request_method
        ActiveSupport::ExecutionContext[:filtered_path]       = request.filtered_path
        ActiveSupport::ExecutionContext[:filtered_parameters] = request.filtered_parameters
        ActiveSupport::ExecutionContext[:user_agent]          = request.user_agent
        ActiveSupport::ExecutionContext[:request_id]          = request.request_id
        ActiveSupport::ExecutionContext[:remote_ip]           = request.remote_ip
        ActiveSupport::ExecutionContext[:host]                = request.host

        @app.call(env)
      end
    end
  end
end
