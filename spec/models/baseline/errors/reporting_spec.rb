# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Baseline::Errors reporting" do
  around do |example|
    previous = Baseline.configuration.capture_exceptions
    Baseline.configuration.capture_exceptions = true
    Baseline::Errors::Issue.delete_all
    example.run
  ensure
    Baseline.configuration.capture_exceptions = previous
    ActiveSupport::ExecutionContext.clear
  end

  it "captures Rails.error.report with normalized execution context" do
    ActiveSupport::ExecutionContext[:request_method] = "GET"
    ActiveSupport::ExecutionContext[:filtered_path] = "/boom"
    ActiveSupport::ExecutionContext[:filtered_parameters] = { token: "secret", id: 1 }

    Rails.error.report(
      RuntimeError.new("boom"),
      handled: false,
      context: { queue_name: :default },
      source: "application.action_dispatch"
    )

    issue = Baseline::Errors::Issue.order(:id).last

    expect(issue.context).to include(
      "request_method" => "GET",
      "filtered_path" => "/boom",
      "queue_name" => "default",
      "source" => "application.action_dispatch"
    )
  end
end
