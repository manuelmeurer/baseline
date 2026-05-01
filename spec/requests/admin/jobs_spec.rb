# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Jobs", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    stub_const("TestJob", Class.new(ActiveJob::Base) do
      limits_concurrency key: -> { "test-lock" }, duration: 1.hour

      def perform; end
    end)
    clear_solid_queue
  end

  describe "GET /jobs" do
    it "redirects unauthenticated users to the admin login" do
      get "/jobs"

      expect(response).to redirect_to("http://admin.localtest.me/login")
    end

    it "renders the queues page for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/jobs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jobs")
      expect(response.body).to include("Queues")
    end
  end

  describe "GET /jobs/failed/jobs" do
    it "renders the job status page for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/jobs/failed/jobs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Failed jobs")
    end
  end

  describe "GET /jobs/workers" do
    it "renders the workers page for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/jobs/workers"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Workers")
    end
  end

  describe "GET /jobs/recurring_tasks" do
    it "renders the recurring tasks page for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/jobs/recurring_tasks"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recurring tasks")
    end
  end

  describe "POST /jobs/:id/retry" do
    it "retries a failed job" do
      authenticate_admin
      job = create_solid_queue_job(:failed)

      post "/jobs/#{job.active_job_id}/retry"

      expect(response).to redirect_to("/jobs/failed/jobs")
      expect(job.reload).to be_ready
    end
  end

  describe "POST /jobs/:id/discard" do
    it "discards a failed job" do
      authenticate_admin
      job = create_solid_queue_job(:failed)

      post "/jobs/#{job.active_job_id}/discard"

      expect(response).to redirect_to("/jobs/failed/jobs")
      expect(SolidQueue::Job.exists?(job.id)).to be(false)
    end

    it "discards a pending job" do
      authenticate_admin
      job = create_solid_queue_job(:pending)

      post "/jobs/#{job.active_job_id}/discard"

      expect(response).to redirect_to("/jobs/pending/jobs")
      expect(SolidQueue::Job.exists?(job.id)).to be(false)
    end

    it "discards a scheduled job" do
      authenticate_admin
      job = create_solid_queue_job(:scheduled)

      post "/jobs/#{job.active_job_id}/discard"

      expect(response).to redirect_to("/jobs/scheduled/jobs")
      expect(SolidQueue::Job.exists?(job.id)).to be(false)
    end
  end

  describe "POST /jobs/:id/dispatch" do
    it "dispatches a scheduled job immediately" do
      authenticate_admin
      job = create_solid_queue_job(:scheduled, scheduled_at: 1.day.from_now)

      post "/jobs/#{job.active_job_id}/dispatch"

      expect(response).to redirect_to("/jobs/scheduled/jobs")
      expect(job.reload.scheduled_execution.scheduled_at).to be <= Time.current
    end

    it "dispatches a blocked job immediately" do
      authenticate_admin
      job = create_solid_queue_job(:blocked)

      post "/jobs/#{job.active_job_id}/dispatch"

      expect(response).to redirect_to("/jobs/blocked/jobs")
      expect(job.reload).to be_ready
    end
  end

  describe "queue pauses" do
    it "pauses and resumes a queue" do
      authenticate_admin
      create_solid_queue_job(:pending, queue_name: "default")

      post "/jobs/queues/default/pause"
      expect(response).to redirect_to("/jobs/queues")
      expect(SolidQueue::Queue.find_by_name("default")).to be_paused

      delete "/jobs/queues/default/pause"
      expect(response).to redirect_to("/jobs/queues")
      expect(SolidQueue::Queue.find_by_name("default")).not_to be_paused
    end
  end

  describe "PATCH /jobs/recurring_tasks/:id" do
    it "enqueues a recurring task" do
      authenticate_admin
      stub_const("TestRecurringJob", Class.new(ActiveJob::Base) do
        def perform; end
      end)
      task = SolidQueue::RecurringTask.create!(
        key:        "daily",
        schedule:   "every day at 9am",
        class_name: "TestRecurringJob",
        arguments:  [],
        queue_name: "default",
        priority:   0,
        static:     false
      )

      expect {
        patch "/jobs/recurring_tasks/#{task.key}"
      }.to change(SolidQueue::Job, :count).by(1)

      expect(response).to redirect_to(%r{\Ahttp://admin.localtest.me/jobs/})
    end
  end

  private
    def authenticate_admin
      get "/", params: { t: admin_user.login_token }
    end

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
        SolidQueue::RecurringTask
      ].each(&:delete_all)
    end

    def create_solid_queue_job(status, queue_name: "default", scheduled_at: Time.current)
      active_job_id = SecureRandom.uuid

      SolidQueue::Job.create!(
        queue_name:,
        class_name:    "TestJob",
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
        "job_class"  => "TestJob",
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
      when :blocked
        job.update!(concurrency_key: "test-lock")
        SolidQueue::BlockedExecution.create!(
          job:,
          queue_name:,
          priority:        job.priority,
          concurrency_key: "test-lock",
          expires_at:      1.hour.from_now
        )
      else
        raise "Unsupported status: #{status}"
      end
    end
end
