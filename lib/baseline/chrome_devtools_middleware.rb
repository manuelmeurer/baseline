# frozen_string_literal: true

module Baseline
  class ChromeDevtoolsMiddleware
    NAMESPACE = "822f7bc5-aa31-4b9f-9c14-df23d95578a1" # Randomly generated UUID

    def initialize(app)
      @app = app
    end

    def call(env)
      unless env["PATH_INFO"] == "/.well-known/appspecific/com.chrome.devtools.json"
        return @app.call(env)
      end

      body = {
        workspace: {
          uuid: Digest::UUID.uuid_v5(NAMESPACE, Rails.root.to_s),
          root: Rails.root.to_s
        }
      }

      headers = {
        "Content-Type"  => "application/json",
        "Cache-Control" => "public, max-age=#{365 * 24 * 60 * 60}, immutable",
        "Expires"       => (Time.now + 1.year).httpdate
      }

      [200, headers, [body.to_json]]
    end
  end
end
