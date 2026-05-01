# frozen_string_literal: true

module Baseline
  module Storage
    class << self
      def available?
        defined?(ActiveStorage::Blob) &&
          defined?(ActiveStorage::Attachment) &&
          data_source_exists?(ActiveStorage::Blob.table_name) &&
          data_source_exists?(ActiveStorage::Attachment.table_name)
      end

      def format_bytes(bytes)
        bytes = bytes.to_i
        return "0 B" if bytes.zero?

        units    = %w[B KB MB GB TB PB]
        exponent = [(Math.log(bytes) / Math.log(1024)).to_i, units.size - 1].min
        value    = bytes.to_f / (1024**exponent)

        "#{format("%.2f", value)} #{units.fetch(exponent)}"
      end

      private

        def data_source_exists?(table_name)
          ActiveRecord::Base.connection.data_source_exists?(table_name)
        rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError
          false
        end
    end
  end
end
