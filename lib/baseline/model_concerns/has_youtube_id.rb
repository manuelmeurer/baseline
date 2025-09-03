# frozen_string_literal: true

module Baseline
  module HasYoutubeID
    SUFFIX_REGEX = /_id\z/

    def self.[](attribute = :youtube_id)
      unless attribute.match?(SUFFIX_REGEX)
        raise ArgumentError, "Invalid attribute: #{attribute}"
      end

      Module.new do
        define_method attribute.to_s.sub(SUFFIX_REGEX, "_url") do |embed: false|
          if value = public_send(attribute)
            embed ?
              "https://www.youtube.com/embed/#{value}" :
              "https://www.youtube.com/watch?v=#{value}"
          end
        end
      end
    end
  end
end
