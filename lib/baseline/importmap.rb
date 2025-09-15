# frozen_string_literal: true

module Baseline
  module Importmap
    def self.extended(importmap)
      require "addressable"

      def importmap.jsdelivr(path) = File.join("https://cdn.jsdelivr.net/npm", path)

      importmap.enable_integrity!

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
      importmap.pin "@rails/request.js",          to: importmap.jsdelivr("@rails/request.js@0/dist/requestjs.min.js")
      importmap.pin "bootstrap",                  to: importmap.jsdelivr("bootstrap@5.3/+esm")
      importmap.pin "cookieconsent",              to: importmap.jsdelivr("vanilla-cookieconsent@3/dist/cookieconsent.esm.js")
      importmap.pin "js-cookie",                  to: importmap.jsdelivr("js-cookie@3/dist/js.cookie.min.js")
      importmap.pin "local-time",                 to: "local-time.es2017-esm.js"
      importmap.pin "sentry",                     to: "https://js.sentry-cdn.com/#{sentry_public_key}.min.js"

      if fontawesome_id = Rails.application.env_credentials.fontawesome_id
        importmap.pin "fontawesome",              to: "https://kit.fontawesome.com/#{fontawesome_id}.js"
      end

      importmap.pin "application_controller"
      importmap.pin "controllers",                to: "controllers/index.js"
      importmap.pin "base_controller",            to: "baseline/base_controller.js"

      {
        "@rails/actiontext"    => "actiontext.esm.js",
        "@rails/activestorage" => "activestorage.esm.js",
        "gallery_controller"   => "baseline/gallery_controller.js",
        "lexxy"                => "lexxy.js",
        "photoswipe-lightbox"  => importmap.jsdelivr("photoswipe@5/dist/photoswipe-lightbox.esm.min.js"),
        "photoswipe"           => importmap.jsdelivr("photoswipe@5/dist/photoswipe.esm.min.js")
      }.each do |name, to|
        importmap.pin name,
          to:,
          preload: false
      end

      Rails
        .root
        .join("app", "javascript", "controllers", "*")
        .then { Dir[_1] }
        .map { File.basename _1 if File.directory? _1 }
        .compact
        .each do |namespace|
          preload = Rails
            .configuration
            .stimulus_app_namespaces
            .fetch(namespace.to_sym)
            .map(&:to_s)

          importmap.pin(namespace, preload:)

          importmap.pin_all_from(
            "app/javascript/controllers/#{namespace}",
            preload:,
            under: "controllers/#{namespace}"
          )
        end
    end
  end
end
