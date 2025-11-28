# frozen_string_literal: true

module Baseline
  class DbTasks < Thor
    include Thor::Actions

    namespace :db

    SUCCESS_PREFIX = "SUCCESS!"
    DIR            = File.join("storage", "db_backups")

    class_option :host, type: :string, required: true
    class_option :app_path, type: :string, required: true

    def self.exit_on_failure? = true

    desc "backup", "backup"
    def backup
      pathname = send(:"backup_#{db_config.adapter}")

      Pathname(DIR)
        .children
        .select { File.ctime(_1) < 3.days.ago.beginning_of_day }
        .each { File.delete _1 }

      say "#{SUCCESS_PREFIX} #{pathname}"
    end

    desc "sync", "sync"
    def sync
      extension = {
        sqlite:     "sqlite3",
        postgresql: "sql"
      }.fetch(db_config.adapter.to_sym) {
        say "Error: unsupported database adapter: #{db_config.adapter}"
        exit 1
      }

      file = Pathname(DIR)
        .children
        .sort
        .select { _1.extname == ".#{extension}" }
        .last

      unless file
        say "No backup file found to sync."
        exit 1
      end
      say "Found latest backup file: #{file}"

      say "Compressing backup file..."
      run "gzip -9 -k #{file}"

      compressed_file = "#{file}.gz"

      unless File.exist?(compressed_file)
        say "Error: compressed file not found: #{compressed_file}"
        exit 1
      end

      rclone_remote =
        r2_bucket =
          "db-backups"

      say "Checking if rclone remote '#{rclone_remote}' exists..."
      remotes = run("rclone listremotes", capture: true).split("\n").map { _1.delete_suffix(":") }
      unless remotes.include?(rclone_remote)
        say "Error: rclone remote '#{rclone_remote}' not found. Please configure it first."
        exit 1
      end
      say "Rclone remote '#{rclone_remote}' found."

      remote = "#{rclone_remote}:#{r2_bucket}/#{options[:app_path]}/"

      say "Uploading compressed file to remote host..."
      run "rclone copy #{compressed_file} #{remote}"

      say "Deleting compressed file..."
      File.delete compressed_file

      say "Deleting remote backups older than 30 days..."
      run "rclone --min-age 30d delete #{remote}"
    end

    option :fresh, default: false, type: :boolean, desc: "Create a fresh backup on the remote host"
    option :local, type: :string, desc: "Path to the local backup file to restore"
    desc "restore", "restore"
    def restore
      case
      when options[:fresh] && options[:local]
        say "Error: both 'fresh' and 'local_path' are set. Please set only one."
        exit 1
      when options[:fresh]
        say <<~MSG
          I will take a fresh database backup on #{options[:host]} and restore it to the current development database.
          The development database will be overwritten.
        MSG
      when options[:local]
        say <<~MSG
          I will restore the backup from #{options[:local]} to the current development database.
          The development database will be overwritten.
        MSG
      else
        say <<~MSG
          I will attempt to download the latest database backup from #{options[:host]} and restore it to the current development database.
          The development database will be overwritten.
          If you want to create a fresh backup instead, run this command with the --fresh option
          If you want to restore a local_path backup file, run this command with --local path_to_local_backup.sql
        MSG
      end
      say "Press Ctrl+C to cancel or Enter to continue."

      STDIN.gets

      case
      when options[:fresh]
        say "Creating database backup on #{options[:host]}..."

        result = run("ssh #{options[:host]} 'cd #{options[:app_path]}/current && bin/db backup'", capture: true)
          .split("\n")
          .last

        unless result.start_with?(SUCCESS_PREFIX)
          say "Error: expected the result to start with '#{SUCCESS_PREFIX}': #{result}"
          exit 1
        end

        remote_path = result.delete_prefix(SUCCESS_PREFIX).strip
      when options[:local]
        unless File.exist?(options[:local])
          say "Error: file not found: #{options[:local]}"
          exit 1
        end
        local_path = options[:local]
      else
        say "Locating latest database backup on #{options[:host]}..."

        remote_path = run("ssh #{options[:host]} 'cd #{options[:app_path]}/current && if [ -d #{DIR} ]; then ls #{DIR}/*.* | xargs realpath; fi'", capture: true)
          .split("\n")
          .first

        unless remote_path
          say "Error: no database backups found, aborting..."
          exit 1
        end

        say <<~MSG
          Found latest database backup: #{remote_path}
          Restore this backup?
          Press Ctrl+C to cancel or Enter to continue.
        MSG

        STDIN.gets
      end

      if remote_path
        say "Downloading database backup: #{remote_path}"
        run "scp #{options[:host]}:#{remote_path} ."
        local_path = File.basename(remote_path)
      end

      say "Restoring database backup: #{local_path}"

      send :"restore_#{db_config.adapter}", local_path
    end

    private

      def backup_sqlite
        pathname = backup_pathname(
          db_config.database.split("/").last
        )

        FileUtils.cp \
          db_config.database,
          pathname

        pathname
      end

      def backup_postgresql
        pathname = backup_pathname(
          "#{db_config.database}.sql"
        )

        pg_dump_command = <<~CMD
          PGPASSWORD='#{db_config.password}' \
            pg_dump \
              --format=c \
              --no-acl \
              --no-password \
              --no-owner \
              --no-comments \
              -h '#{db_config.host}' \
              -p '#{db_config.port}' \
              -U '#{db_config.username}' \
              #{db_config.database} \
                > #{pathname}
        CMD

        unless run(pg_dump_command)
          say "Error creating database backup. Command executed: #{pg_dump_command}"
          exit 1
        end

        pathname
      end

      def restore_sqlite(local_path)
        FileUtils.rm_f(db_config.database)
        FileUtils.cp(local_path, db_config.database)
        say "Probably the -shm and -wal files need to be removed, otherwise we might get a corrupted file error."
      end

      def restore_postgresql(local_path)
        run <<~CMD
          psql \
            --dbname #{db_config.database} \
            --username #{db_config.username} \
            --command "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" &&
          pg_restore \
            --dbname #{db_config.database} \
            --no-owner \
            --username #{db_config.username} \
            --role #{db_config.username} \
            #{local_path}
        CMD
      end

      def db_config
        require "ostruct"

        ActiveRecord::Base
          .connection_db_config
          .configuration_hash
          .merge(
            adapter: ActiveRecord::Base.connection.adapter_name.downcase
          ).then {
            OpenStruct.new _1
          }
      end

      def now_timestamp = Time.current.to_fs(:number)

      def backup_pathname(suffix)
        Rails.root.join(
          DIR,
          "#{now_timestamp}_#{suffix}"
        ).tap {
          FileUtils.mkdir_p(_1.dirname)
        }
      end
  end
end
