# frozen_string_literal: true

class Baseline::Jobs::JobProxy < ActiveJob::Base
  class UnsupportedError < StandardError; end

  attr_reader :job_class_name

  def initialize(job_data)
    super
    @job_class_name = job_data["job_class"]
    deserialize(job_data)
  end

  def serialize
    super.tap do |json|
      json["job_class"] = @job_class_name
    end
  end

  def perform_now
    raise UnsupportedError, "A JobProxy doesn't support immediate execution, only enqueuing."
  end

  def duration
    finished_at - scheduled_at
  end

  Baseline::Jobs::STATUSES.each do |status|
    define_method "#{status}?" do
      self.status == status
    end
  end
end
