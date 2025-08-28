# frozen_string_literal: true

module Baseline
  module HasTasks
    extend ActiveSupport::Concern

    included do
      Task.add_taskable(self)

      has_many :tasks,
        as:        :taskable,
        dependent: :destroy
    end
  end
end
