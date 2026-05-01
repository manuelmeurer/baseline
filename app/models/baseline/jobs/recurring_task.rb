# frozen_string_literal: true

class Baseline::Jobs::RecurringTask
  include ActiveModel::Model

  attr_accessor :id, :job_class_name, :command, :arguments, :schedule,
    :last_enqueued_at, :next_time, :queue_name, :priority

  def jobs
    Baseline::Jobs.jobs.where(recurring_task_id: id)
  end

  def enqueue
    Baseline::Jobs::SolidQueue.enqueue_recurring_task(id)
  end

  def runnable?
    Baseline::Jobs::SolidQueue.can_enqueue_recurring_task?(id)
  end
end
