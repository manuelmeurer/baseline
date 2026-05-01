# frozen_string_literal: true

class Baseline::Admin::Jobs::Queues::PausesController < Baseline::Admin::Jobs::ApplicationController
  include Baseline::Jobs::QueueScoped

  def create
    @queue.pause

    redirect_back fallback_location: queues_url
  end

  def destroy
    @queue.resume

    redirect_back fallback_location: queues_url
  end
end
