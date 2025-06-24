# frozen_string_literal: true

Rake::Task["db:drop"].enhance(["db:terminate_connections"])

namespace :db do
  desc "Terminate all connections to the current database"
  task terminate_connections: :environment do
    ActiveRecord::Base.connection.execute <<~SQL
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = current_database()
      AND pid <> pg_backend_pid();
    SQL
  end
end
