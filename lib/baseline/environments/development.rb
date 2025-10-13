# frozen_string_literal: true

Warning[:deprecated] = true

Rails.application.configure do
  config.hotwire.spark.html_extensions += %w[haml]

  config.hosts.push(
    *Rails.application.env_credentials.host!.then { [_1, ".#{_1}"] }
  )

  config.assets.quiet = true
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.middleware.use Baseline::ChromeDevtoolsMiddleware
end
