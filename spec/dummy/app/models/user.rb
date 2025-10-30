# frozen_string_literal: true

class User < ApplicationRecord
  include Baseline::ActsAsUser,
          Baseline::HasDummyImageAttachment[:photo],
          Baseline::HasEmail,
          Baseline::HasGender,
          Baseline::HasFirstAndLastName,
          Baseline::HasFriendlyID,
          Baseline::HasLocale[default: :de],
          Baseline::HasLoginToken,
          Baseline::HasPassword[default: "password"]

  has_one :admin_user, dependent: :destroy

  has_one_attached :photo

  validates :email, uniqueness: { allow_nil: true }
  validates :gender, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :photo, content_type: common_image_file_types

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
#  raffle          :boolean          not null
#  remember_token  :string
#  slug            :string           not null
#  subscriptions   :json             not null
#  title           :string
#  vip             :boolean          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
