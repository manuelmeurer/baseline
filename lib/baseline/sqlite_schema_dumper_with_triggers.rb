# frozen_string_literal: true

# Extends Rails' SQLite schema dumper to also emit triggers, so FTS5
# triggers added by `Baseline::Migration::FTS5#create_fts5_index` survive
# `db:schema:dump` / `db:schema:load` round-trips.
#
# Without this, Rails' Ruby schema dumper preserves the FTS5 virtual table
# but silently drops every CREATE TRIGGER, leaving a stale index in any
# database loaded from `schema.rb`.
module Baseline
  module SQLiteSchemaDumperWithTriggers
    private
      def virtual_tables(stream)
        super
        dump_sqlite_triggers(stream)
      end

      def dump_sqlite_triggers(stream)
        rows = @connection.execute(<<~SQL)
          SELECT name, sql
          FROM sqlite_master
          WHERE type = 'trigger' AND sql IS NOT NULL
          ORDER BY name
        SQL

        return if rows.empty?

        stream.puts
        stream.puts "  # Triggers (e.g. FTS5 sync triggers)."
        rows.each do |row|
          sql = row.fetch("sql").strip
          stream.puts "  execute <<~SQL"
          sql.each_line do |line|
            stream.puts "    #{line.rstrip}"
          end
          stream.puts "  SQL"
        end
      end
  end
end

ActiveRecord::ConnectionAdapters::SQLite3::SchemaDumper
  .prepend(Baseline::SQLiteSchemaDumperWithTriggers)
