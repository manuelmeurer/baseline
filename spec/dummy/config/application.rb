# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    include Baseline::ApplicationCore

    config.load_defaults 8.0

    config.autoload_lib ignore: %w[tasks]

    config.time_zone = "Europe/Berlin"

    config.action_controller.include_all_helpers = false

    config.action_view.image_loading = :lazy

    config.dartsass.builds = {
      "." => "."
    }

    config.middleware.insert 0, Rack::Deflater
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*", headers: :any, methods: :get
      end
    end

    config.i18n.available_locales             = %i[en de]
    config.i18n.default_locale                = config.i18n.available_locales.first
    config.i18n.fallbacks                     = [I18n.default_locale]
    config.i18n.raise_on_missing_translations = true

    config.active_storage.queues.analysis   = :default
    config.active_storage.queues.purge      = :default
    config.active_storage.variant_processor = :vips

    config.solid_queue.clear_finished_jobs_after = 1.month

    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { database: { writing: :queue } }

    config.cache_store = :solid_cache_store, { compressor: Baseline::ZstdCompressor }
  end
end
