# frozen_string_literal: true

module Baseline
  module ApplicationCore
    extend ActiveSupport::Concern

    included do
      config.load_defaults Rails.version.to_f

      baseline_spec = Gem.loaded_specs["baseline"]
      # Don't use `is_a?` here, since Bundler::Source::Git inherits from Bundler::Source::Path.
      if baseline_spec.source.class == Bundler::Source::Path
        {
          "lib"            => %i[rb haml],
          "app/javascript" => %i[js]
        }.each {
          config.watchable_dirs[File.join(baseline_spec.full_gem_path, _1)] = _2
        }

        if Rails.env.development?
          config.to_prepare do
            Zeitwerk::Registry
              .loaders
              .each
              .detect { _1.tag == "baseline" }
              .reload
          end
        end
      end

      # https://guides.rubyonrails.org/configuring.html#config-exceptions-app
      config.exceptions_app = ->(env) {
        request = ActionDispatch::Request.new(env)

        begin
          request.formats
        rescue ActionDispatch::Http::MimeNegotiation::InvalidType
          request.set_header "CONTENT_TYPE", "text/html"
        end

        routes.call(env)
      }

      config.assets.integrity_hash_algorithm = "sha256"

      config.paths.add "app/models",
        eager_load: true,
        glob:       "**/*"

      config.revision = begin
        Rails
          .root
          .join("REVISION")
          .then { File.read _1 }
      rescue Errno::ENOENT
        `git rev-parse HEAD 2> /dev/null`.chomp
      end.presence or
        raise "Could not load revision."

      %i[host protocol port]
        .index_with { env_credentials[_1] }
        .compact
        .then do |url_options|
          Rails.application.routes.default_url_options =
            config.action_mailer.default_url_options =
            url_options

          url_options
            .transform_keys {
              { protocol: :scheme }.fetch(_1, _1)
            }.then {
              config.asset_host = Addressable::URI.new(_1).to_s
            }
        end

      config.active_storage.queues.analysis        = :default
      config.active_storage.queues.purge           = :default
      config.active_storage.variant_processor      = :vips
      config.active_storage.resolve_model_to_route = :rails_storage_proxy

      if defined?(SolidQueue)
        config.active_job.queue_adapter = :solid_queue

        config.solid_queue.clear_finished_jobs_after = 1.month
        config.solid_queue.connects_to = { database: { writing: :queue } }
      end

      if defined?(MissionControl::Jobs)
        config.mission_control.jobs.base_controller_class   = "MissionControl::Jobs::BaseController"
        config.mission_control.jobs.http_basic_auth_enabled = false
      end

      config.cache_store = :solid_cache_store, { compressor: Baseline::ZstdCompressor }

      config.autoload_lib ignore: %w[tasks]

      config.dartsass.builds = {
        "." => "."
      }

      config.time_zone = "Europe/Berlin"

      config.i18n.raise_on_missing_translations = true

      config.action_controller.include_all_helpers = false

      config.middleware.insert 0, Rack::Deflater
      config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins "*"
          resource "*", headers: :any, methods: :get
        end
      end

      config.action_view.image_loading = :lazy
    end

    def env_credentials(env = Rails.env)
      @env_credentials ||= {}
      @env_credentials[env] ||= begin
        creds = credentials.dup
        env_creds = creds.delete(:"__#{env}")
        creds.delete_if { _1.start_with?("__") }
        creds.deep_merge(env_creds || {})
      end
    end
  end
end
