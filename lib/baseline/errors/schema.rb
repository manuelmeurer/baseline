# frozen_string_literal: true

module Baseline
  module Errors
    module Schema
      class << self
        def define
          connection = Baseline::Errors::ApplicationRecord.connection_pool.with_connection { _1 }

          return if connection.data_source_exists?(Baseline::Errors.table_name)

          connection.create_table Baseline::Errors.table_name, if_not_exists: true do |t|
            t.string   :fingerprint,       null: false
            t.string   :class_name,        null: false
            t.text     :message,           null: false
            t.json     :backtrace,         null: false, default: []
            t.json     :causes,            null: false, default: []
            t.json     :context,           null: false, default: {}
            t.integer  :occurrences_count, null: false, default: 0
            t.datetime :first_seen_at,     null: false
            t.datetime :last_seen_at,      null: false
            t.datetime :resolved_at
            t.timestamps
          end

          {
            fingerprint:  { unique: true },
            class_name:   {},
            last_seen_at: {},
            resolved_at:  {}
          }.each do |column, options|
            connection.add_index Baseline::Errors.table_name, column, if_not_exists: true, **options
          end
        end
      end
    end
  end
end
