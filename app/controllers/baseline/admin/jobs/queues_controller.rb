# frozen_string_literal: true

class Baseline::Admin::Jobs::QueuesController < Baseline::Admin::Jobs::ApplicationController
  before_action :set_queue, only: :show

  def index
    @queues = Baseline::Jobs.queues.sort_by(&:name)
  end

  def show
    @jobs_page = Baseline::Jobs::Page.new(@queue.jobs, page: params[:page].to_i)
  end

  private
    def set_queue
      @queue = Baseline::Jobs.queues[params[:id]]
    end
end
