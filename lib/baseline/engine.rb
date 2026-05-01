# frozen_string_literal: true

module Baseline
  class Engine < ::Rails::Engine
    isolate_namespace Baseline

    class << self
      def require_jobs_extension(path, constant_name)
        constant_name.constantize
      rescue NameError
        require_relative path
      end
    end

    initializer "baseline.inflections", before: :setup_main_autoloader do
      overrides = Baseline::Inflector::ACRONYMS.to_h { [_1.downcase, _1] }
      Rails.autoloaders.main.inflector.inflect(overrides)

      ActiveSupport::Inflector.inflections(:en) do |inflect|
        Baseline::Inflector::ACRONYMS.each(&inflect.method(:acronym))
      end
    end

    # hotwire-spark assumes all controllers have view helpers, which is not
    # the case for ActionController::API controllers. Guard accordingly.
    initializer "baseline.hotwire_spark_api_fix" do
      if defined?(Hotwire::Spark::Middleware)
        Hotwire::Spark::Middleware.prepend(Module.new do
          private def interceptable_request?
            super && @request.controller_instance.respond_to?(:helpers)
          end
        end)
      end
    end

    initializer "baseline.after_initialize" do |app|
      begin
        require "sitemap_generator"
      rescue LoadError
      else
        require "baseline/sitemap_generator"
      end

      I18n.load_path += Dir[root.join("config", "locales", "**", "*.yml")]

      app.config.assets.paths << root.join("app", "javascript")

      components_path = root.join("lib", "baseline", "components")
      config.paths["app/views"] << components_path
      ActiveSupport.on_load(:action_controller) do
        append_view_path components_path
      end

      ActionController::Renderers.add :ics do |object, _|
        ical = object.try(:to_ical) || object
        send_data ical, type: Mime::Type.new("text/calendar")
      end
    end

    initializer "baseline.assets.precompile" do |app|
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
    end

    initializer "baseline.errors.install", after: :load_config_initializers do
      Baseline::Errors.install!
    end

    initializer "baseline.sqlite_schema_dumper_with_triggers" do
      ActiveSupport.on_load(:active_record_sqlite3adapter) do
        require "baseline/sqlite_schema_dumper_with_triggers"
      end
    end

    config.baseline = ActiveSupport::OrderedOptions.new unless config.try(:baseline)
    config.baseline.jobs = ActiveSupport::OrderedOptions.new

    config.before_initialize do
      config.baseline.jobs.backtrace_cleaner ||= Rails::BacktraceCleaner.new

      config.baseline.jobs.each do |key, value|
        Baseline::Jobs.public_send("#{key}=", value)
      end
    end

    initializer "baseline.jobs.active_job.extensions" do
      ActiveSupport.on_load :active_job do
        Baseline::Engine.require_jobs_extension \
          "../active_job/errors/invalid_operation",
          "ActiveJob::Errors::InvalidOperation"
        Baseline::Engine.require_jobs_extension \
          "../active_job/errors/job_not_found_error",
          "ActiveJob::Errors::JobNotFoundError"
        Baseline::Engine.require_jobs_extension \
          "../active_job/errors/query_error",
          "ActiveJob::Errors::QueryError"
        Baseline::Engine.require_jobs_extension \
          "../active_job/executing",
          "ActiveJob::Executing"
        Baseline::Engine.require_jobs_extension \
          "../active_job/execution_error",
          "ActiveJob::ExecutionError"
        Baseline::Engine.require_jobs_extension \
          "../active_job/failed",
          "ActiveJob::Failed"
        Baseline::Engine.require_jobs_extension \
          "../active_job/jobs_relation",
          "ActiveJob::JobsRelation"
        Baseline::Engine.require_jobs_extension \
          "../active_job/job_proxy",
          "ActiveJob::JobProxy"
        Baseline::Engine.require_jobs_extension \
          "../active_job/queue",
          "ActiveJob::Queue"
        Baseline::Engine.require_jobs_extension \
          "../active_job/queues",
          "ActiveJob::Queues"
        Baseline::Engine.require_jobs_extension \
          "../active_job/querying",
          "ActiveJob::Querying"

        include ActiveJob::Querying
        include ActiveJob::Executing
        include ActiveJob::Failed
        ActiveJob.extend ActiveJob::Querying::Root
      end
    end

    config.before_initialize do
      unless config.active_job.queue_adapter&.to_sym == :solid_queue
        raise "Baseline::Jobs requires config.active_job.queue_adapter = :solid_queue"
      end
    end

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { load _1 }
    end
  end
end
