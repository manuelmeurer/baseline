# frozen_string_literal: true

module Baseline
  module Tasks
    class Create < ApplicationService
      def call(task = nil, if_absent: :reassign, **args)
        task ||= Task.new(args)

        if task.responsible.is_a?(AdminUser)
          case
          when covering_admin_user = task.responsible.try(:covering_admin_user)
            case if_absent
            when :abort then return
            when :ignore
            when :reassign
              task.details = [
                task.details,
                "[assigned to #{covering_admin_user} since #{task.responsible} is absent]"
              ].compact_blank
                .join("\n\n")
              task.responsible = covering_admin_user
            else raise Error, "Unexpected if_absent: #{if_absent}"
            end
          when task.responsible.try(:deactivated?)
            old_responsible = task.responsible
            task.responsible = AdminUser.manuel
            task.details = [
              "Assigned to #{task.responsible} since #{old_responsible} is deactivated.",
              task.details
            ].compact
              .join("\n\n")
          end
        end

        task.save!

        try :after_create, task

        task
      end
    end
  end
end
