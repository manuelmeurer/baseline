# frozen_string_literal: true

class Task < ApplicationRecord
  include Baseline::ActsAsTask
  _baseline_finalize
end

# == Schema Information
#
# Table name: tasks
#
#  id               :integer          not null, primary key
#  creator_type     :string
#  details          :text
#  done_at          :datetime
#  due_on           :date             not null
#  identifier       :string
#  priority         :integer          not null
#  responsible_type :string           not null
#  taskable_type    :string
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  creator_id       :integer
#  responsible_id   :integer          not null
#  taskable_id      :integer
#  todoist_id       :string
#
