# frozen_string_literal: true

class Event < ApplicationRecord
end

# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  description :text
#  duration    :integer          not null
#  ended_at    :datetime
#  started_at  :datetime         not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
