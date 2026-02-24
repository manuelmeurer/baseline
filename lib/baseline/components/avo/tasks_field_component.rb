# frozen_string_literal: true

module Baseline
  module Avo
    class TasksFieldComponent < ApplicationComponent
      include FieldHelpers

      def initialize(record:, params:)
        @record, @params = record, params
        @tasks  = record.tasks.order(due_on: :desc)
      end

      def call
        tab_id           = "#{ActionView::RecordIdentifier.dom_id(@record)}-tasks"
        tab_class        = "px-2 py-1 text-sm cursor-pointer"
        active_tab_class = "#{tab_class} font-bold border-b-2 border-blue-600"

        tag.div do
          tag.div(class: "flex gap-4 border-b border-gray-200") do
            tag.button(
              "Undone (#{@tasks.undone.size})",
              id:      "tab-undone-#{tab_id}",
              class:   active_tab_class,
              onclick: "document.getElementById('panel-undone-#{tab_id}').classList.remove('hidden'); document.getElementById('panel-done-#{tab_id}').classList.add('hidden'); this.className = '#{active_tab_class}'; document.getElementById('tab-done-#{tab_id}').className = '#{tab_class}'"
            ) +
            tag.button(
              "Done (#{@tasks.done.size})",
              id:      "tab-done-#{tab_id}",
              class:   tab_class,
              onclick: "document.getElementById('panel-done-#{tab_id}').classList.remove('hidden'); document.getElementById('panel-undone-#{tab_id}').classList.add('hidden'); this.className = '#{active_tab_class}'; document.getElementById('tab-undone-#{tab_id}').className = '#{tab_class}'"
            ) +
            tag.div(class: "ml-auto") do
              render_avo_button(
                helpers.avo.new_resources_task_path(
                  via_relation:       :taskable,
                  via_relation_class: @record.class.name,
                  via_record_id:      @record.to_param,
                  via_resource_class: "Avo::Resources::#{@record.class.name}"
                ),
                icon:  "heroicons/outline/plus",
                title: "New task",
                modal: true
              )
            end
          end +
          tag.div(id: "panel-undone-#{tab_id}") do
            render_task_list(@tasks.undone)
          end +
          tag.div(id: "panel-done-#{tab_id}", class: "hidden") do
            render_task_list(@tasks.done)
          end
        end
      end

      private

        def render_task_list(tasks)
          tasks
            .map {
              render_task _1
            }.then {
              safe_join _1
            }
        end

        def render_task(task)
          task_resource = ::Avo::Resources::Task.new(record: task, params: @params)

          done_undone_button =
            if task.done?
              render_avo_button \
                Baseline::Avo::Resources::Task::Actions::Undone,
                resource: task_resource,
                icon:     "heroicons/outline/minus-circle",
                title:    "Undone"
            else
              render_avo_button \
                Baseline::Avo::Resources::Task::Actions::Done,
                resource: task_resource,
                icon:     "heroicons/outline/check-circle",
                title:    "Done"
            end

          show_button = render_avo_button(
            helpers.avo.resources_task_path(task),
            icon:  "heroicons/outline/eye",
            title: "Show",
            modal: true
          )

          edit_button = render_avo_button(
            helpers.avo.edit_resources_task_path(task),
            icon:  "heroicons/outline/pencil",
            title: "Edit"
          )

          tag.div(class: "flex items-center justify-between py-2 gap-3 border-b border-gray-100 last:border-b-0") do
            tag.div(class: "flex flex-col") do
              tag.span(task.title, class: "font-medium") +
              tag.div(class: "flex gap-3 text-sm text-gray-500 mt-1") do
                [
                  tag.span(I18n.l(task.due_on).to_s),
                  tag.span(task.responsible.first_name.to_s),
                  unless task.priority_medium?
                    tag.span(task.priority.to_s.capitalize, class: "text-#{{ high: "red-600", low: "blue-600" }.fetch(task.priority.to_sym)} font-medium")
                  end
                ].then {
                  safe_join _1
                }
              end
            end +
            tag.div(class: "flex gap-2") do
              safe_join([done_undone_button, show_button, edit_button])
            end
          end
        end
    end
  end
end
