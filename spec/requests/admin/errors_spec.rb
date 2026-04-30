# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Errors", type: :request do
  let(:admin_user) { create(:admin_user) }

  around do |example|
    previous = Baseline.configuration.capture_exceptions
    Baseline.configuration.capture_exceptions = true
    example.run
  ensure
    Baseline.configuration.capture_exceptions = previous
  end

  describe "GET /errors" do
    it "redirects unauthenticated users to the admin login" do
      get "/errors"

      expect(response).to redirect_to("http://admin.localtest.me/login")
    end

    it "renders the dashboard for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/errors"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Errors")
    end
  end

  describe "GET /errors/issues" do
    it "renders the issue index for authenticated users" do
      Baseline::Errors::Issue.create!(
        fingerprint:       "abc123",
        class_name:        "RuntimeError",
        message:           "boom",
        backtrace:         ["app/models/example.rb:1"],
        causes:            [],
        context:           { source: "application.action_dispatch" },
        occurrences_count: 1,
        first_seen_at:     Time.current,
        last_seen_at:      Time.current
      )

      get "/", params: { t: admin_user.login_token }

      get "/errors/issues"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("RuntimeError")
      expect(response.body).to include("boom")
    end
  end

  describe "GET /errors/issues/:id" do
    it "renders the issue details" do
      issue = Baseline::Errors::Issue.create!(
        fingerprint:       "def456",
        class_name:        "ArgumentError",
        message:           "bad input",
        backtrace:         ["app/services/demo.rb:3"],
        causes:            [{ class_name: "StandardError", message: "root cause", backtrace: ["app/services/demo.rb:1"] }],
        context:           { source: "application.active_job", queue_name: "default" },
        occurrences_count: 2,
        first_seen_at:     Time.current,
        last_seen_at:      Time.current
      )

      get "/", params: { t: admin_user.login_token }

      get "/errors/issues/#{issue.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ArgumentError")
      expect(response.body).to include("bad input")
      expect(response.body).to include("root cause")
    end
  end
end
