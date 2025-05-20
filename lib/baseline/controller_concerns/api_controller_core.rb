# frozen_string_literal: true

module Baseline
  module APIControllerCore
    extend ActiveSupport::Concern

    included do
      if defined?(MemoWise)
        prepend MemoWise
        memo_wise :json_body
      end

      include ActionController::HttpAuthentication::Token::ControllerMethods,
              RobotsSitemap

      error_class = Class.new(StandardError) do
        attr_reader :status

        def initialize(message, status: :bad_request)
          @status = status
          super message
        end
      end

      const_set :Error, error_class

      rescue_from self::Error, with: :render_error
    end

    private

      def origin
        request
          .headers["origin"]
          .presence
      end

      def json_body
        request
          .body
          .read
          .then {
            JSON.parse _1,
              symbolize_names: true
          }
      end

      def render_error(error)
        render \
          json:   { error: error.message },
          status: error.status
      end
  end
end
