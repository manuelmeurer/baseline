# frozen_string_literal: true

class Subscription < ApplicationRecord
  include Baseline::ActsAsSubscription

  def self.identifiers
    %w[
      newsletter
      secret_newsletter
    ]
  end

  _baseline_finalize
end

# == Schema Information
#
# Table name: subscriptions
#
#  id         :integer          not null, primary key
#  identifier :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
