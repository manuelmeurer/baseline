# frozen_string_literal: true

module Baseline
  module ApplicationCore
    extend ActiveSupport::Concern

    included do
      config.load_defaults Rails.version.to_f

      def config.add_database_configuration(primary_adapter)
        define_singleton_method(:database_configuration) do
          base = {
            pool: 100 # https://island94.org/2024/09/secret-to-rails-database-connection-pool-size
          }
          sqlite_base = base.merge(
            adapter: "sqlite3",
            timeout: 5000
          )

          # Parallel Tests sets the env var TEST_ENV_NUMBER.
          add_parallel_suffix = ->(base, env) {
            [
              base,
              (ENV["TEST_ENV_NUMBER"]&.rjust(2, "0") if env == :test)
            ].compact_blank.join("_")
          }

          db_config = {
            postgresql: ->(key, env) {
              valid_keys = %i[host database port username password]
              config = Rails.application.env_credentials(env).db
              invalid_keys = config.keys - valid_keys
              if invalid_keys.any?
                raise "Invalid database credential keys for #{env}: #{invalid_keys}"
              end
              valid_keys.each do |k|
                if env_value = ENV["DB_#{k.upcase}"]
                  config[k] = env_value
                end
              end
              config
                .reverse_merge(base)
                .merge(
                  adapter:  "postgresql",
                  encoding: "unicode"
                ).tap {
                  _1[:database] = add_parallel_suffix.call(_1[:database], env)
                }.to_h
            },
            sqlite: ->(key, env) {
              basename = [
                env,
                (key unless key == :primary)
              ].compact.join("_")
              basename = add_parallel_suffix.call(basename, env)
              sqlite_base
                .unless(key == :primary) {
                  _1.merge migrations_paths: "db/#{key}_migrate"
                }.merge \
                  database: "storage/#{basename}.sqlite3"
            }
          }

          %i[development test production].index_with do |env|
            %i[cable cache queue].index_with {
              db_config[:sqlite].call(_1, env)
            }.reverse_merge(
              primary: db_config[primary_adapter].call(:primary, env)
            ).tap {
              unless _1.keys.first == :primary
                raise "The first key must be :primary, but it is #{_1.keys.first}"
              end
            }
          end
        end
      end

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

      if defined?(::Avo)
        config.to_prepare do
          ::Avo::Fields::BaseField.include \
            ActionView::Helpers::TagHelper,
            ActionView::Helpers::NumberHelper,
            Avo::FieldHelpers

          ::Avo::ResourcesController.include \
            Avo::ResourcesControllable

          ::Avo::ApplicationController.include \
            Avo::ApplicationControllable
        end

        # Tell Zeitwerk that url_helpers.rb defines UrlHelpers (not URLHelpers).
        # This is needed because Avo uses UrlHelpers but we have URL as an acronym.
        if Gem::Version.new(::Avo::VERSION) >= Gem::Version.new("4")
          raise "is this still needed?"
        end
        Rails.autoloaders.main.inflector.inflect("url_helpers" => "UrlHelpers")
      end

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

      url_options_keys = %i[host protocol]
      url_options = url_options_keys
        .index_with { env_credentials[_1] }
        .compact

      if url_options.keys == url_options_keys
        # Hatchbox sets a PORT env var in production, which we don't want to use.
        unless Rails.env.production?
          url_options[:port] = ENV.fetch("PORT")
        end

        Rails.application.routes.default_url_options =
          config.action_mailer.default_url_options =
          url_options

        config.asset_host = url_options
          .transform_keys {
            { protocol: :scheme }.fetch(_1, _1)
          }.then {
            Addressable::URI.new(_1)
          }.to_s
      else
        missing = url_options_keys - url_options.keys
        warn "WARNING: #{missing.join(", ")} not found in credentials, skipping asset_host configuration"
      end

      config.active_storage.queues.analysis        = :default
      config.active_storage.queues.purge           = :default
      config.active_storage.routes_prefix          = "/attachments"
      config.active_storage.variant_processor      = :vips

      if defined?(SolidQueue)
        config.active_job.queue_adapter = :solid_queue

        config.solid_queue.clear_finished_jobs_after = 1.month
        config.solid_queue.connects_to = { database: { writing: :queue } }
      end

      if defined?(MissionControl::Jobs)
        config.mission_control.jobs.base_controller_class   = "MissionControl::Jobs::BaseController"
        config.mission_control.jobs.http_basic_auth_enabled = false
        config.mission_control.jobs.show_console_help       = false
      end

      config.cache_store = :solid_cache_store, { compressor: Baseline::ZstdCompressor }

      config.autoload_lib ignore: %w[tasks]

      if config.respond_to?(:dartsass)
        config.dartsass.builds = {
          "." => "."
        }
        config.dartsass.build_options << "--quiet"
      end

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

      config.filter_parameters += %i[
        passw secret token _key crypt salt certificate otp ssn cvv cvc
      ]
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
