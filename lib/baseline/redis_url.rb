# frozen_string_literal: true

module Baseline
  module RedisURL
    DATABASES = %i[
      uplink
      rails_bump
      ruby_docs
      note_to_self
      tasks
      spendex
      funlocked
    ]

    def self.fetch(identifier = nil)
      @redis_url ||= Rails.application.env_credentials.redis_url || begin
        if defined?(Rails)
          identifier ||= Rails.application.class.to_s.deconstantize.underscore.to_sym
        end

        unless identifier
          raise "Redis URL identifier not set."
        end
        unless db = DATABASES.index(identifier)
          raise %(Redis db for identifier "#{identifier}" not found.)
        end

        host = Rails.application.env_credentials.redis_host!

        "redis://#{host}/#{db}"
      end
    end
  end
end
