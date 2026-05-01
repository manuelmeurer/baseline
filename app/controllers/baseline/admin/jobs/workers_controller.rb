# frozen_string_literal: true

class Baseline::Admin::Jobs::WorkersController < Baseline::Admin::Jobs::ApplicationController
  def index
    @workers_page = Baseline::Jobs::Page.new(workers_relation, page: params[:page].to_i)
    @workers_count = @workers_page.total_count
  end

  def show
    worker = Baseline::Jobs::SolidQueue.find_worker(params[:id])
    raise Baseline::Jobs::Errors::ResourceNotFound, "Worker not found" unless worker

    @worker = Baseline::Jobs::Worker.new(**worker)
  end

  private
    def workers_relation
      Baseline::Jobs::WorkersRelation.new
    end
end
