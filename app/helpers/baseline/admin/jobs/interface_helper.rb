# frozen_string_literal: true

module Baseline::Admin::Jobs::InterfaceHelper
  def blank_status_notice(message)
    tag.div message, class: "mt-6 text-center text-xl text-base-content/60"
  end

  def modifier_for_status(status)
    case status.to_s
    when "failed"      then "badge-error"
    when "blocked"     then "badge-warning"
    when "finished"    then "badge-success"
    when "scheduled"   then "badge-info"
    when "in_progress" then "badge-primary"
    else "badge-ghost"
    end
  end
end
