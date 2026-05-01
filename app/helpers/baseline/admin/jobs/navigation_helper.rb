# frozen_string_literal: true

module Baseline::Admin::Jobs::NavigationHelper
  attr_reader :page_title, :current_section

  def navigation_sections
    { queues: [ "Queues", queues_path ] }.tap do |sections|
      supported_job_statuses.without(:pending).each do |status|
        sections[navigation_section_for_status(status)] = [
          "#{status.to_s.titleize} jobs (#{jobs_count_with_status(status)})",
          jobs_path(status)
        ]
      end

      sections[:workers] = [
        "Workers",
        workers_path
      ]

      sections[:recurring_tasks] = [
        "Recurring tasks",
        recurring_tasks_path
      ]
    end
  end

  def navigation_section_for_status(status)
    if status.nil? || status == :pending
      :queues
    else
      "#{status}_jobs".to_sym
    end
  end

  def navigation(title: nil, section: nil)
    @page_title = title
    @current_section = section
  end

  def jobs_count_with_status(status)
    count = Baseline::Jobs.jobs.with_status(status).count
    if count.infinite?
      "..."
    else
      number_to_human(count,
        format: "%n%u",
        units: {
          thousand: "K",
          million: "M",
          billion: "B",
          trillion: "T",
          quadrillion: "Q"
        })
    end
  end
end
