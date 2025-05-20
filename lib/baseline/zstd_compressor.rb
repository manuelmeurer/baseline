# frozen_string_literal: true

module Baseline
  module ZstdCompressor
    def self.deflate(payload)
      ::Zstd.compress(payload, level: 10)
    end

    def self.inflate(payload)
      payload.start_with?("\x78") ?
        Zlib.inflate(payload) :
        ::Zstd.decompress(payload)
    end
  end
end
