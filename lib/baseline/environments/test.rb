# frozen_string_literal: true

Warning[:deprecated] = true

Rails.application.configure do
  # https://gist.github.com/skatkov/e482617b2a1f9635738a0b66ec0cb327
  config.to_prepare do
    ActiveSupport.on_load :active_record_postgresqladapter do
      self.create_unlogged_tables = true
    end
  end

  config.log_level = :fatal
end
