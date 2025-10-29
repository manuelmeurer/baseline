# frozen_string_literal: true

class AdminUser < ApplicationRecord
  include Baseline::ActsAsAdminUser,
          Baseline::UserProxy

  belongs_to :user

  _baseline_finalize
end
