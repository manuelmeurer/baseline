# frozen_string_literal: true

class Baseline::Jobs::Relation
  include Enumerable

  STATUSES = Baseline::Jobs::STATUSES

  PROPERTIES = %i[ queue_name status offset_value limit_value job_class_name worker_id recurring_task_id finished_at ]
  attr_reader *PROPERTIES, :default_page_size

  delegate :last, :[], :reverse, to: :to_a
  delegate :logger, to: Baseline::Jobs

  ALL_JOBS_LIMIT = 100_000_000

  def initialize(default_page_size: Baseline::Jobs.default_page_size)
    @default_page_size = default_page_size
    set_defaults
  end

  def where(job_class_name: nil, queue_name: nil, worker_id: nil, recurring_task_id: nil, finished_at: nil)
    arguments = { job_class_name:,
      queue_name: queue_name&.to_s,
      worker_id:,
      recurring_task_id:,
      finished_at:
    }.compact

    clone_with **arguments
  end

  def with_status(status)
    if status.to_sym.in? Baseline::Jobs::STATUSES
      clone_with status: status.to_sym
    else
      self
    end
  end

  Baseline::Jobs::STATUSES.each do |status|
    define_method status do
      with_status(status)
    end

    define_method "#{status}?" do
      self.status == status
    end
  end

  def offset(offset)
    clone_with offset_value: offset
  end

  def limit(limit)
    clone_with limit_value: limit
  end

  def count
    if loaded?
      to_a.length
    else
      query_count
    end
  end

  alias length count
  alias size count

  def empty?
    count == 0
  end

  def to_s
    properties_with_values = PROPERTIES.collect do |name|
      value = public_send(name)
      "#{name}: #{value}" unless value.nil?
    end.compact.join(", ")
    "<Jobs with [#{properties_with_values}]> (loaded: #{loaded?})"
  end

  alias inspect to_s

  def each(&block)
    loaded_jobs&.each(&block) || load_jobs(&block)
  end

  def retry_all
    ensure_failed_status
    Baseline::Jobs::SolidQueue.retry_all_jobs(self)
    nil
  end

  def retry_job(job)
    ensure_failed_status
    Baseline::Jobs::SolidQueue.retry_job(job, self)
  end

  def discard_all
    Baseline::Jobs::SolidQueue.discard_all_jobs(self)
    nil
  end

  def discard_job(job)
    Baseline::Jobs::SolidQueue.discard_job(job, self)
  end

  def dispatch_job(job)
    raise Baseline::Jobs::Errors::InvalidOperation, "This operation can only be performed on blocked or scheduled jobs, but this job is #{job.status}" unless job.blocked? || job.scheduled?

    Baseline::Jobs::SolidQueue.dispatch_job(job, self)
  end

  def find_by_id(job_id)
    Baseline::Jobs::SolidQueue.find_job(job_id, self)
  end

  def find_by_id!(job_id)
    Baseline::Jobs::SolidQueue.find_job(job_id, self) or raise Baseline::Jobs::Errors::JobNotFound.new(job_id, self)
  end

  def job_class_names(from_first: 500)
    first(from_first).collect(&:job_class_name).uniq
  end

  def reload
    @count = nil
    @loaded_jobs = nil

    self
  end

  def in_batches(of: default_page_size, order: :asc, &block)
    validate_looping_in_batches_is_possible

    case order
    when :asc
      in_ascending_batches(of:, &block)
    when :desc
      in_descending_batches(of:, &block)
    else
      raise "Unsupported order: #{order}. Valid values: :asc, :desc."
    end
  end

  def paginated?
    offset_value > 0 || limit_value_provided?
  end

  def limit_value_provided?
    limit_value.present? && limit_value != ALL_JOBS_LIMIT
  end

  private
    attr_reader :loaded_jobs
    attr_writer *PROPERTIES

    def set_defaults
      self.offset_value = 0
      self.limit_value = ALL_JOBS_LIMIT
    end

    def clone_with(**properties)
      dup.reload.tap do |relation|
        properties.each do |key, value|
          relation.send("#{key}=", value)
        end
      end
    end

    def query_count
      @count ||= Baseline::Jobs::SolidQueue.jobs_count(self)
    end

    def load_jobs
      @loaded_jobs = []
      perform_each do |job|
        @loaded_jobs << job
        yield job
      end
    end

    def perform_each
      current_offset = offset_value
      pending_count = limit_value || Float::INFINITY

      begin
        limit = [ pending_count, default_page_size ].min
        page = offset(current_offset).limit(limit)
        jobs = Baseline::Jobs::SolidQueue.fetch_jobs(page)
        finished = jobs.empty?
        Array(jobs).each { |job| yield job }
        current_offset += limit
        pending_count -= jobs.length
      end until finished || pending_count.zero?
    end

    def loaded?
      !@loaded_jobs.nil?
    end

    def ensure_failed_status
      raise Baseline::Jobs::Errors::InvalidOperation, "This operation can only be performed on failed jobs, but these jobs are #{status}" unless failed?
    end

    def validate_looping_in_batches_is_possible
      raise Baseline::Jobs::Errors::InvalidOperation, "Looping in batches is not compatible with providing offset or limit" if paginated?
    end

    def in_ascending_batches(of:)
      current_offset = 0
      max = count
      begin
        page = offset(current_offset).limit(of)
        current_offset += of
        logger.info page
        yield page
        wait_batch_delay
      end until current_offset >= max
    end

    def in_descending_batches(of:)
      current_offset = count - of

      begin
        limit = current_offset < 0 ? of + current_offset : of
        page = offset([ current_offset, 0 ].max).limit(limit)
        current_offset -= of
        logger.info page
        yield page
        wait_batch_delay
      end until current_offset + of <= 0
    end

    def wait_batch_delay
      sleep Baseline::Jobs.delay_between_bulk_operation_batches if Baseline::Jobs.delay_between_bulk_operation_batches.to_i > 0
    end
end
