# frozen_string_literal: true

class AdminUser < ApplicationRecord
  include Baseline::ActsAsAdminUser,
          Baseline::UserProxy

  belongs_to :user

  _baseline_finalize
end

# == Schema Information
#
# Table name: admin_users
#
#  id               :integer          not null, primary key
#  alternate_emails :json             not null
#  position         :string
#  tokens           :json             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer          not null
#
