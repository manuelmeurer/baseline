# frozen_string_literal: true

if github_config = Rails.application.env_credentials.github
  require "octokit"
  Octokit.configuration.access_token = github_config.access_token!
end
