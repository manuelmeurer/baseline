# frozen_string_literal: true

class User < ApplicationRecord
  include Baseline::ActsAsUser

  has_one :admin_user, dependent: :destroy

  has_many :user_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :user_subscriptions

  validates :email, uniqueness: { allow_nil: true }
  validates :gender, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  def default_password = "password"
  def default_locale   = :de

  _baseline_finalize
end

# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  alternate_emails :json             not null
#  email            :string
#  first_name       :string           not null
#  gender           :integer
#  last_name        :string           not null
#  locale           :string           not null
#  password_digest  :string           not null
#  remember_token   :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
