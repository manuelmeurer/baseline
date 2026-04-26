# frozen_string_literal: true

Rails.application.routes.draw do
  extend Baseline::Routes

  draw :web

  root to: redirect(URLManager.url_options(:web))
end
