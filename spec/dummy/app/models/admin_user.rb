# frozen_string_literal: true

class AdminUser < ApplicationRecord
  include Baseline::ActsAsAdminUser

  belongs_to :user

  # Must be included after the user association is defined.
  include Baseline::UserProxy

  _baseline_finalize
end

# == Schema Information
#
# Table name: admin_users
#
#  id         :integer          not null, primary key
#  tokens     :json             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
