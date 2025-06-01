# frozen_string_literal: true

module Baseline
  module External
    module Google
      module Oauth
        class Service < ApplicationService
          def initialize(name, admin_user = nil)
            @name    = name
            @service = Helpers.initialize_service(name, admin_user)

            super()
          end

          def method_missing(method, ...)
            if @service.respond_to?(method)
              @service.public_send(method, ...)
            else
              super
            end
          end
        end
      end
    end
  end
end
