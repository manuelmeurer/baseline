# frozen_string_literal: true

class Baseline::Jobs::Worker
  include ActiveModel::Model

  attr_accessor :id, :name, :hostname, :last_heartbeat_at, :configuration, :raw_data

  def jobs
    @jobs ||= Baseline::Jobs.jobs.in_progress.where(worker_id: id)
  end
end
