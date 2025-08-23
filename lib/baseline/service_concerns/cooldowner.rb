# frozen_string_literal: true

module Baseline
  module Cooldowner
    private

      def cooldown!(period)
        Rails.cache.write \
          cooldown_cache_key,
          period.from_now,
          expires_in: period
      end

      def cooldown?      = !!cooldown_until
      def cooldown_until = Rails.cache.read(cooldown_cache_key)

      def cooldown_cache_key
        [
          self.class.to_s,
          :cooldown_until
        ]
      end
  end
end
