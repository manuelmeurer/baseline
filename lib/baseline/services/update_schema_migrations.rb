# frozen_string_literal: true

module Baseline
  class UpdateSchemaMigrations < ApplicationService
    ::SchemaMigration = Class.new(ActiveRecord::Base)

    def call
      SchemaMigration.delete_all
      Dir[Rails.root.join('db', 'migrate', '*')].each do |file|
        unless version = file[%r(db/migrate/(\d{14})), 1]
          raise Error, "Could not determine version from file: #{file}"
        end
        SchemaMigration.create! version: version
      end
    end
  end
end
