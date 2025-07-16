# frozen_string_literal: true

module Baseline
  module Importmap
    def self.extended(importmap)
      require "addressable"

      sentry_public_key = Rails
        .application
        .env_credentials
        .sentry
        &.dsn
        &.then {
          Addressable::URI
            .parse(_1)
            .user
        } ||
          "dummy"

      importmap.pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
      importmap.pin "@hotwired/stimulus",         to: "stimulus.min.js"
      importmap.pin "@hotwired/turbo-rails",      to: "turbo.min.js"
      importmap.pin "@rails/request.js",          to: "https://cdn.jsdelivr.net/npm/@rails/request.js@0/dist/requestjs.min.js"
      importmap.pin "bootstrap",                  to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3/+esm"
      importmap.pin "cookieconsent",              to: "https://cdn.jsdelivr.net/npm/vanilla-cookieconsent@3/dist/cookieconsent.esm.js"
      importmap.pin "js-cookie",                  to: "https://cdn.jsdelivr.net/npm/js-cookie@3/dist/js.cookie.min.js"
      importmap.pin "sentry",                     to: "https://js.sentry-cdn.com/#{sentry_public_key}.min.js"

      if fontawesome_id = Rails.application.env_credentials.fontawesome_id
        importmap.pin "fontawesome",              to: "https://kit.fontawesome.com/#{fontawesome_id}.js"
      end

      importmap.pin "application_controller"
      importmap.pin "baseline_controller",        to: "baseline/controller.js"
      importmap.pin "controllers",                to: "controllers/index.js"

      Rails
        .root
        .join("app", "javascript", "controllers", "*")
        .then { Dir[_1] }
        .map { File.basename _1 if File.directory? _1 }
        .compact
        .each do |namespace|
          importmap.pin namespace
          importmap.pin_all_from "app/javascript/controllers/#{namespace}",
            under:   "controllers/#{namespace}",
            preload: Rails.configuration.stimulus_app_namespaces.fetch(namespace.to_sym).map(&:to_s)
        end
    end
  end
end
