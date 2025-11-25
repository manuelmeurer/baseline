# frozen_string_literal: true

class UserSubscription < ApplicationRecord
  belongs_to :user, inverse_of: :user_subscriptions
  belongs_to :subscription, inverse_of: :user_subscriptions

  validates :user, uniqueness: { scope: :subscription }

  _baseline_finalize
end

# == Schema Information
#
# Table name: user_subscriptions
#
#  id              :integer          not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  subscription_id :integer          not null
#  user_id         :integer          not null
#
