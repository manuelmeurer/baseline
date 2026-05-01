# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::Jobs::SolidQueue do
  before do
    stub_const("SolidQueueTestJob", Class.new(ActiveJob::Base) do
      limits_concurrency key: -> { "test-lock" }, duration: 1.hour

      def perform; end
    end)
    clear_solid_queue
  end

  describe ".queues" do
    it "returns queue size and pause state" do
      create_solid_queue_job(:pending, queue_name: "critical")
      SolidQueue::Queue.find_by_name("critical").pause

      expect(described_class.queues).to contain_exactly(
        hash_including(name: "critical", size: 1, active: false)
      )
    end
  end

  describe ".fetch_jobs" do
    it "returns proxied jobs matching relation filters" do
      matching_job = create_solid_queue_job(:failed, queue_name: "critical")
      create_solid_queue_job(:failed, queue_name: "default")

      jobs = described_class.fetch_jobs(
        Baseline::Jobs.jobs.failed.where(queue_name: "critical")
      )

      expect(jobs.map(&:job_id)).to contain_exactly(matching_job.active_job_id)
      expect(jobs.first).to be_failed
      expect(jobs.first.last_execution_error.message).to eq("boom")
    end
  end

  describe "job actions" do
    it "retries failed jobs" do
      job = create_solid_queue_job(:failed)
      proxy = Baseline::Jobs.jobs.failed.find_by_id!(job.active_job_id)

      described_class.retry_job(proxy, Baseline::Jobs.jobs.failed)

      expect(job.reload).to be_ready
    end

    it "discards pending jobs" do
      job = create_solid_queue_job(:pending)
      proxy = Baseline::Jobs.jobs.pending.find_by_id!(job.active_job_id)

      described_class.discard_job(proxy, Baseline::Jobs.jobs.pending)

      expect(SolidQueue::Job.exists?(job.id)).to be(false)
    end

    it "dispatches scheduled jobs immediately" do
      job = create_solid_queue_job(:scheduled, scheduled_at: 1.day.from_now)
      proxy = Baseline::Jobs.jobs.scheduled.find_by_id!(job.active_job_id)

      described_class.dispatch_job(proxy, Baseline::Jobs.jobs.scheduled)

      expect(job.reload.scheduled_execution.scheduled_at).to be <= Time.current
    end
  end

  describe "recurring tasks" do
    it "lists and enqueues recurring tasks" do
      stub_const("SolidQueueRecurringTestJob", Class.new(ActiveJob::Base) do
        def perform; end
      end)
      task = SolidQueue::RecurringTask.create!(
        key:        "daily",
        schedule:   "0 9 * * *",
        class_name: "SolidQueueRecurringTestJob",
        arguments:  [],
        queue_name: "default",
        priority:   0,
        static:     false
      )

      expect(described_class.recurring_tasks).to contain_exactly(
        hash_including(id: "daily", job_class_name: "SolidQueueRecurringTestJob")
      )
      expect {
        described_class.enqueue_recurring_task(task.key)
      }.to change(SolidQueue::Job, :count).by(1)
    end
  end

  describe "workers" do
    it "returns worker records from Solid Queue processes" do
      process = SolidQueue::Process.create!(
        kind:              "Worker",
        last_heartbeat_at: Time.current,
        pid:               1234,
        hostname:          "worker-host",
        metadata:          { "queues" => ["default"] },
        name:              "worker-1"
      )

      workers = described_class.fetch_workers(Baseline::Jobs::WorkersRelation.new)

      expect(workers.map(&:id)).to contain_exactly(process.id)
      expect(workers.first.name).to eq("PID: 1234")
      expect(described_class.find_worker(process.id)).to include(hostname: "worker-host")
    end
  end

  private
    def clear_solid_queue
      [
        SolidQueue::BlockedExecution,
        SolidQueue::ClaimedExecution,
        SolidQueue::FailedExecution,
        SolidQueue::ReadyExecution,
        SolidQueue::RecurringExecution,
        SolidQueue::ScheduledExecution,
        SolidQueue::Job,
        SolidQueue::Pause,
        SolidQueue::Process,
        SolidQueue::RecurringTask,
        SolidQueue::Semaphore
      ].each(&:delete_all)
    end

    def create_solid_queue_job(status, queue_name: "default", scheduled_at: Time.current)
      active_job_id = SecureRandom.uuid

      SolidQueue::Job.create!(
        queue_name:,
        class_name:    "SolidQueueTestJob",
        arguments:     serialized_job_arguments(active_job_id:, queue_name:),
        active_job_id:,
        scheduled_at:
      ).tap do |job|
        delete_solid_queue_executions(job)
        create_solid_queue_execution(job, status, queue_name:, scheduled_at:)
      end
    end

    def serialized_job_arguments(active_job_id:, queue_name:)
      {
        "job_class"  => "SolidQueueTestJob",
        "job_id"     => active_job_id,
        "arguments"  => [],
        "queue_name" => queue_name,
        "priority"   => nil
      }
    end

    def delete_solid_queue_executions(job)
      [
        SolidQueue::BlockedExecution,
        SolidQueue::ClaimedExecution,
        SolidQueue::FailedExecution,
        SolidQueue::ReadyExecution,
        SolidQueue::RecurringExecution,
        SolidQueue::ScheduledExecution
      ].each { _1.where(job:).delete_all }
    end

    def create_solid_queue_execution(job, status, queue_name:, scheduled_at:)
      case status
      when :failed
        SolidQueue::FailedExecution.create!(
          job:,
          error: { "exception_class" => "RuntimeError", "message" => "boom", "backtrace" => ["line"] }
        )
      when :pending
        SolidQueue::ReadyExecution.create!(job:, queue_name:, priority: job.priority)
      when :scheduled
        SolidQueue::ScheduledExecution.create!(
          job:,
          queue_name:,
          priority:     job.priority,
          scheduled_at:
        )
      else
        raise "Unsupported status: #{status}"
      end
    end
end
