# frozen_string_literal: true

Warning[:deprecated] = true

Rails.application.configure do
  if config.try(:hotwire)&.respond_to?(:spark)
    config.hotwire.spark.html_extensions += %w[haml]
    config.hotwire.spark.html_paths      += %w[app/components]
  end

  if defined?(SolidQueue)
    config.solid_queue.logger = ActiveSupport::Logger.new(STDOUT)
  end

  # Make sure this file can be loaded even if `host`
  # is not set yet, i.e. to regenerate the credentials file.
  if host = Rails.application.env_credentials.host
    config.hosts.push(host, ".#{host}")
  end

  config.active_record.protected_environments = []

  config.assets.quiet = true
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.middleware.use Baseline::ChromeDevtoolsMiddleware
end
