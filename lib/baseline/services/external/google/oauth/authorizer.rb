# frozen_string_literal: true

module Baseline
  module External
    module Google
      module Oauth
        class Authorizer < ApplicationService
          def initialize(admin_user = nil)
            @authorizer = Helpers.initialize_authorizer(admin_user)
            super()
          end

          def auth_url(login_hint)
            @authorizer.get_authorization_url \
              login_hint:
          end

          def auth_credentials(code)
            @authorizer.get_credentials_from_code \
              user_id: "default",
              code:
          end

          def scopes
            @authorizer.instance_variable_get("@scope")
          end
        end
      end
    end
  end
end
