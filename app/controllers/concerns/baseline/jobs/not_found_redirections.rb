# frozen_string_literal: true

module Baseline::Jobs::NotFoundRedirections
  extend ActiveSupport::Concern

  included do
    rescue_from(Baseline::Jobs::Errors::JobNotFound) do |error|
      redirect_to best_location_for_job_relation(error.job_relation), alert: error.message
    end

    rescue_from(Baseline::Jobs::Errors::ResourceNotFound) do |error|
      redirect_to best_location_for_resource_not_found_error(error), alert: error.message
    end
  end

  private
    def best_location_for_job_relation(job_relation)
      case
      when job_relation.failed?
        jobs_path(:failed)
      when job_relation.queue_name.present?
        queue_path(job_relation.queue_name)
      else
        queues_path
      end
    end

    def best_location_for_resource_not_found_error(error)
      if error.message.match?(/recurring task/i)
        recurring_tasks_path
      else
        queues_url
      end
    end
end
