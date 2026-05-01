# frozen_string_literal: true

class Baseline::Admin::Jobs::RecurringTasksController < Baseline::Admin::Jobs::ApplicationController
  before_action :set_recurring_task, only: [ :show, :update ]
  before_action :ensure_recurring_task_can_be_enqueued, only: :update

  def index
    @recurring_tasks = Baseline::Jobs::SolidQueue.recurring_tasks.collect do |task|
      Baseline::Jobs::RecurringTask.new(**task)
    end
  end

  def show
    @jobs_page = Baseline::Jobs::Page.new(@recurring_task.jobs, page: params[:page].to_i)
  end

  def update
    if (job = @recurring_task.enqueue) && job.successfully_enqueued?
      redirect_to \
        job_path(job.job_id),
        notice: "Enqueued recurring task #{@recurring_task.id}"
    else
      redirect_to \
        recurring_task_path(@recurring_task.id),
        alert: "Something went wrong enqueuing this recurring task"
    end
  end

  private
    def set_recurring_task
      task = Baseline::Jobs::SolidQueue.find_recurring_task(params[:id])
      raise Baseline::Jobs::Errors::ResourceNotFound, "Recurring task not found" unless task

      @recurring_task = Baseline::Jobs::RecurringTask.new(**task)
    end

    def ensure_recurring_task_can_be_enqueued
      unless @recurring_task.runnable?
        redirect_to \
          recurring_task_path(@recurring_task.id),
          alert: "This task can't be enqueued"
      end
    end
end
