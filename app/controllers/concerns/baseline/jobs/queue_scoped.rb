# frozen_string_literal: true

module Baseline::Jobs::QueueScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_queue
  end

  private
    def set_queue
      @queue = Baseline::Jobs.queues[params[:queue_id]]
      return if @queue

      raise Baseline::Jobs::Errors::ResourceNotFound, queue_not_found_message
    end

    def queue_not_found_message
      "Queue '#{params[:queue_id]}' not found"
    end
end
