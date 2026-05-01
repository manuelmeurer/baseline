# frozen_string_literal: true

class Baseline::Jobs::Queue
  attr_reader :name

  def initialize(name, size: nil, active: nil)
    @name = name
    @size = size
    @active = active
  end

  def size
    @size ||= Baseline::Jobs::SolidQueue.queue_size(name)
  end

  alias length size

  def clear
    Baseline::Jobs::SolidQueue.clear_queue(name)
  end

  def empty?
    size == 0
  end

  def pause
    Baseline::Jobs::SolidQueue.pause_queue(name)
  end

  def resume
    Baseline::Jobs::SolidQueue.resume_queue(name)
  end

  def paused?
    !active?
  end

  def active?
    return @active unless @active.nil?
    @active = !Baseline::Jobs::SolidQueue.queue_paused?(name)
  end

  def jobs
    Baseline::Jobs.jobs.pending.where(queue_name: name)
  end

  def reload
    @active = @size = nil
    self
  end

  def id
    name.parameterize
  end

  alias to_param id
end
