# frozen_string_literal: true

module Baseline
  module HasPassword
    extend ActiveSupport::Concern

    included do
      has_secure_password

      validates :password,
        length:    { minimum: 8, maximum: 50 },
        allow_nil: true
    end
  end
end
