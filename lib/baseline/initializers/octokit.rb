# frozen_string_literal: true

if github_config = Rails.application.env_credentials.github
  require "octokit"
  Octokit.access_token = github_config.access_token!
end
