# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::Errors::Subscriber do
  subject(:subscriber) { described_class.new }

  around do |example|
    previous = Baseline.configuration.capture_exceptions
    Baseline.configuration.capture_exceptions = true
    Baseline::Errors::Issue.delete_all
    example.run
  ensure
    Baseline.configuration.capture_exceptions = previous
    ActiveSupport::ExecutionContext.clear
  end

  it "creates a grouped issue with normalized context" do
    error = RuntimeError.new("boom")
    error.set_backtrace(["#{Rails.root}/app/models/demo.rb:1"])

    ActiveSupport::ExecutionContext[:request_method] = "GET"
    ActiveSupport::ExecutionContext[:filtered_path] = "/demo"

    subscriber.report(
      error,
      handled:  false,
      severity: :error,
      context:  { queue_name: :default },
      source:   "application.action_dispatch"
    )

    issue = Baseline::Errors::Issue.order(:id).last

    expect(issue.class_name).to eq("RuntimeError")
    expect(issue.message).to eq("boom")
    expect(issue.occurrences_count).to eq(1)
    expect(issue.context).to include(
      "queue_name" => "default",
      "source" => "application.action_dispatch"
    )
  end

  it "increments occurrences for the same fingerprint and reopens resolved issues" do
    error = RuntimeError.new("boom")
    error.set_backtrace(["#{Rails.root}/app/models/demo.rb:1"])

    subscriber.report(
      error,
      handled:  false,
      severity: :error,
      context:  {},
      source:   "application.action_dispatch"
    )

    issue = Baseline::Errors::Issue.last
    issue.update!(resolved_at: Time.current)

    travel 1.minute do
      subscriber.report(
        error,
        handled:  false,
        severity: :error,
        context:  {},
        source:   "application.action_dispatch"
      )
    end

    issue.reload

    expect(issue.occurrences_count).to eq(2)
    expect(issue.resolved_at).to be_nil
  end

  it "does not capture info severity reports" do
    error = RuntimeError.new("ignore me")
    error.set_backtrace(["#{Rails.root}/app/models/demo.rb:1"])

    subscriber.report(
      error,
      handled:  true,
      severity: :info,
      context:  {},
      source:   "application.action_dispatch"
    )

    expect(Baseline::Errors::Issue.count).to eq(0)
  end
end
