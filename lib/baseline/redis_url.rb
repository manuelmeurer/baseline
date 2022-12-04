module Baseline
  module RedisURL
    DATABASES = %i(
      uplink
      rails_bump
      ruby_docs
      note_to_self
      tasks
    )

    def self.fetch(identifier = nil)
      ENV["REDIS_URL"] ||= begin
        if defined?(Rails)
          identifier ||= Rails.application.class.to_s.deconstantize.underscore.to_sym
        end

        unless identifier
          raise "Redis URL identifier not set."
        end
        unless db = DATABASES.index(identifier)
          raise %(Redis db for identifier "#{identifier}" not found.)
        end

        host = ENV.fetch("REDIS_HOST")

        "redis://#{host}/#{db}"
      end
    end
  end
end
