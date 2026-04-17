# frozen_string_literal: true

if postmark_settings = Rails.application.env_credentials.postmark
  require "postmark-rails"
  Postmark.api_token = postmark_settings.api_token!
end
