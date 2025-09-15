# frozen_string_literal: true

module Baseline
  module ApplicationCore
    extend ActiveSupport::Concern

    included do
      # https://guides.rubyonrails.org/configuring.html#config-exceptions-app
      config.exceptions_app = ->(env) {
        request = ActionDispatch::Request.new(env)

        begin
          request.formats
        rescue ActionDispatch::Http::MimeNegotiation::InvalidType
          request.set_header "CONTENT_TYPE", "text/html"
        end

        routes.call(env)
      }

      config.assets.integrity_hash_algorithm = "sha256"

      config.paths.add "app/models",
        eager_load: true,
        glob:       "**/*"

      config.revision = begin
        Rails
          .root
          .join("REVISION")
          .then { File.read _1 }
      rescue Errno::ENOENT
        `git rev-parse HEAD 2> /dev/null`.chomp
      end.presence or
        raise "Could not load revision."

      %i[host protocol port]
        .index_with { env_credentials[_1] }
        .compact
        .then do |url_options|
          Rails.application.routes.default_url_options =
            config.action_mailer.default_url_options =
            url_options

          url_options
            .transform_keys {
              { protocol: :scheme }.fetch(_1, _1)
            }.then {
              config.asset_host = Addressable::URI.new(_1).to_s
            }
        end
    end

    def env_credentials(env = Rails.env)
      @env_credentials ||= {}
      @env_credentials[env] ||= begin
        creds = credentials.dup
        env_creds = creds.delete(:"__#{env}")
        creds.delete_if { _1.start_with?("__") }
        creds.deep_merge(env_creds || {})
      end
    end
  end
end
