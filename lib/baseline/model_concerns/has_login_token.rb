# frozen_string_literal: true

module Baseline
  module HasLoginToken
    extend ActiveSupport::Concern

    included do
      generates_token_for :login, expires_in: 2.hours
    end

    class_methods do
      def find_by_login_token(token) = find_by_token_for(:login, token)
    end

    def login_token = generate_token_for(:login)
  end
end
