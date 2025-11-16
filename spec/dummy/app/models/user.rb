# frozen_string_literal: true

class User < ApplicationRecord
  include Baseline::ActsAsUser,
          Baseline::HasFriendlyID

  has_one :admin_user, dependent: :destroy

  validates :email, uniqueness: { allow_nil: true }
  validates :gender, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  def default_password = "password"
  def default_locale   = :de

  private

    def should_generate_new_friendly_id?
      first_name_changed? ||
        last_name_changed? ||
        super
    end

    def custom_slug
      [new_slug_identifier, name].join(" ")
    end

    _baseline_finalize
end

# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email           :string
#  first_name      :string           not null
#  gender          :integer
#  last_name       :string           not null
#  locale          :string           not null
#  password_digest :string
#  remember_token  :string
#  slug            :string           not null
#  subscriptions   :json             not null
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
