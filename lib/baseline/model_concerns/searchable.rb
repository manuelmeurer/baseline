# frozen_string_literal: true

module Baseline
  module Searchable
    def self.[](columns = nil, **params)
      Module.new do
        extend ActiveSupport::Concern

        included do
          if columns
            columns = Array(columns)
            invalid_columns = columns - schema_columns.keys
            if invalid_columns.any?
              raise "Invalid columns: #{invalid_columns}"
            end
          end

          case db_adapter = connection.adapter_name.downcase.to_sym
          when :postgresql
            include PgSearch::Model

            if params.key?(:against)
              raise "Don't set 'against', set 'columns' instead."
            end
            if columns
              params[:against] = columns
            end

            params[:using] ||= {
              tsearch: { prefix: true }
            }
            params[:ignoring] ||= :accents

            pg_search_scope :search, params
          when :sqlite
            unless columns
              raise "Must provide 'columns' for SQLite adapter."
            end

            scope :search, ->(query) {
              next all if query.blank?

              columns
                .map { arel_table[_1].matches("%#{sanitize_sql_like(query)}%", "\\") }
                .inject { _1.or(_2) }
                .then { where _1 }
            }
          else
            raise "Unexpected database adapter: #{db_adapter}"
          end
        end
      end
    end
  end
end
