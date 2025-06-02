# frozen_string_literal: true

module Baseline
  module External
    module Google
      module Oauth
        module Helpers
          SERVICES = {
            gmail:    %w[v1 AUTH_GMAIL_READONLY],
            people:   %w[v1 AUTH_CONTACTS],
            drive:    %w[v3 AUTH_DRIVE],
            youtube:  %w[v3 AUTH_YOUTUBE],
            indexing: %w[v3 AUTH_INDEXING]
          }.freeze

          extend self

          mattr_accessor :application_name

          def initialize_user_authorizer(admin_user, names = nil)
            return unless Rails.env.production?

            names ||= SERVICES.keys.reject { use_service_account? _1 }

            require "googleauth"

            client_id, client_secret =
              %i[client_id client_secret].map {
                Rails.application.env_credentials.google.fetch(_1)
              }
            access_token, refresh_token =
              %i[access_token refresh_token].map {
                admin_user ?
                  admin_user.public_send("google_#{_1}") :
                  Rails.application.env_credentials.google.fetch(_1)
              }

            scopes = Array(names).map {
              service_scope _1
            }

            token_store =
              Struct.new(:params) do
                def load(*) = params.to_json
                def store(*);  end
                def delete(*); end
              end.new({
                client_id:,
                scope:         scopes,
                access_token:,
                refresh_token:
              }.compact)

            client_id_object = ::Google::Auth::ClientId.new(client_id, client_secret)
            callback_url     = Rails.application.routes.url_helpers.admin_google_oauth_callback_url

            ::Google::Auth::UserAuthorizer.new \
              client_id_object,
              scopes,
              token_store,
              callback_url
          end

          def initialize_service(name, admin_user = nil)
            return unless Rails.env.production?

            # https://github.com/googleapis/google-api-ruby-client/issues/574
            service_class = [
              name == :youtube ?
                :YouTube :
                name.capitalize,
              name == :people ?
                :ServiceService :
                :Service
            ].join
              .then {
                service_namespace(name).const_get(_1)
              }

            authorization = use_service_account?(name) ?
              Rails
                .application
                .env_credentials
                .google
                .service_account!
                .to_json
                .then { StringIO.new _1 }
                .then {
                  ::Google::Auth::ServiceAccountCredentials.make_creds \
                    json_key_io: _1,
                    scope:       service_scope(name)
                } :
              initialize_user_authorizer(admin_user, name).get_credentials("default")

            unless authorization
              raise Error, "Could not load Google API credentials."
            end

            service_class.new.tap do |service|
              service.client_options.application_name = application_name
              service.authorization                   = authorization
            end
          end

          private

            def service_namespace(name)
              name_and_version = [name, SERVICES.fetch(name).first].join("_")
              require "google/apis/#{name_and_version}"
              ::Google::Apis.const_get(name_and_version.classify)
            end

            def service_scope(name)
              SERVICES
                .fetch(name)
                .last
                .then {
                  service_namespace(name).const_get(_1)
                }
            end

            def use_service_account?(name)
              name == :indexing
            end
        end
      end
    end
  end
end
