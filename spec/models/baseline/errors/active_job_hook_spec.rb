# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Baseline::Errors ActiveJob hook" do
  before do
    stub_const("ExplodingJob", Class.new(ActiveJob::Base) do
      def perform(*args)
        raise ArgumentError, "job boom: #{args.join(",")}" if args.any?
        raise ArgumentError, "job boom"
      end
    end)
  end

  around do |example|
    previous = Baseline.configuration.capture_exceptions
    Baseline.configuration.capture_exceptions = true
    Baseline::Errors.ensure_schema!
    Baseline::Errors::Issue.delete_all
    example.run
  ensure
    Baseline.configuration.capture_exceptions = previous
    ActiveSupport::ExecutionContext.clear
  end

  it "captures queued ActiveJob execution failures" do
    job = ExplodingJob.new("a")

    expect {
      ActiveJob::Base.execute(job.serialize)
    }.to raise_error(ArgumentError, "job boom: a")

    issue = Baseline::Errors::Issue.order(:id).last

    expect(issue.class_name).to eq("ArgumentError")
    expect(issue.context).to include(
      "source" => "application.active_job",
      "job_class" => "ExplodingJob",
      "queue_name" => "default"
    )
  end

  it "does not capture direct perform_now outside a request" do
    expect {
      ExplodingJob.perform_now
    }.to raise_error(ArgumentError, "job boom")

    expect(Baseline::Errors::Issue.count).to eq(0)
  end
end
