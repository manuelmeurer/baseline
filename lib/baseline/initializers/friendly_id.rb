# frozen_string_literal: true

require "friendly_id"

FriendlyId.defaults do |config|
  config.use :reserved
  config.reserved_words = %w[
    admin
    assets
    edit
    images
    index
    javascripts
    login
    logout
    new
    session
    sessions
    stylesheets
    user
    users
  ]
end
