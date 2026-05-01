# frozen_string_literal: true

module Baseline
  module Migration
    # SQLite FTS5 index helper for ActiveRecord migrations.
    #
    # Creates an external-content FTS5 virtual table for a model's
    # searchable columns plus the triggers required to keep it in sync with
    # the source table.
    #
    # Usage:
    #
    #   class AddUsersSearchIndex < ActiveRecord::Migration[8.0]
    #     include Baseline::Migration::FTS5
    #
    #     def up   = create_fts5_index :users
    #     def down = drop_fts5_index   :users
    #   end
    #
    # Columns are inferred from `Model.searchable_params[:columns]`. Pass
    # `columns:` to override.
    #
    # Associated-column search (e.g. searching `admin_users` by joined user
    # attributes) is not handled here. Models that need it should define a
    # custom `:search` scope that delegates to the associated model's own
    # FTS5-backed `:search`.
    module FTS5
      def create_fts5_index(table, columns: nil)
        table   = table.to_s
        columns = (columns || infer_columns(table)).map(&:to_s)

        if columns.empty?
          raise "Cannot create FTS5 index on #{table}: no searchable columns."
        end

        fts_table = "#{table}_fts"
        col_list  = columns.join(", ")
        new_vals  = columns.map { "new.#{_1}" }.join(", ")
        old_vals  = columns.map { "old.#{_1}" }.join(", ")

        # Keep the column/option list on a single line so Rails' SQLite
        # schema dumper (which uses a single-line regex) can parse it back.
        options = "#{col_list}, content='#{table}', content_rowid='id', tokenize='unicode61 remove_diacritics 2'"
        execute "CREATE VIRTUAL TABLE #{fts_table} USING fts5(#{options})"

        execute <<~SQL
          CREATE TRIGGER #{fts_table}_ai AFTER INSERT ON #{table} BEGIN
            INSERT INTO #{fts_table}(rowid, #{col_list})
            VALUES (new.id, #{new_vals});
          END
        SQL

        execute <<~SQL
          CREATE TRIGGER #{fts_table}_ad AFTER DELETE ON #{table} BEGIN
            INSERT INTO #{fts_table}(#{fts_table}, rowid, #{col_list})
            VALUES ('delete', old.id, #{old_vals});
          END
        SQL

        execute <<~SQL
          CREATE TRIGGER #{fts_table}_au AFTER UPDATE ON #{table} BEGIN
            INSERT INTO #{fts_table}(#{fts_table}, rowid, #{col_list})
            VALUES ('delete', old.id, #{old_vals});
            INSERT INTO #{fts_table}(rowid, #{col_list})
            VALUES (new.id, #{new_vals});
          END
        SQL

        execute "INSERT INTO #{fts_table}(#{fts_table}) VALUES('rebuild')"
      end

      def drop_fts5_index(table)
        fts_table = "#{table}_fts"

        execute "DROP TRIGGER IF EXISTS #{fts_table}_ai"
        execute "DROP TRIGGER IF EXISTS #{fts_table}_au"
        execute "DROP TRIGGER IF EXISTS #{fts_table}_ad"
        execute "DROP TABLE IF EXISTS #{fts_table}"
      end

      # Convenience for the common "I added/removed a searchable column"
      # case. Drops and recreates the FTS5 table + triggers; the trailing
      # `rebuild` in `create_fts5_index` repopulates the index from the
      # source table, so no data is lost.
      def recreate_fts5_index(table, columns: nil)
        drop_fts5_index   table
        create_fts5_index table, columns: columns
      end

      private

        def infer_columns(table)
          model  = table.classify.constantize
          params = model.searchable_params or
            raise "#{model} has no searchable_params"
          params.fetch(:columns)
        end
    end
  end
end
