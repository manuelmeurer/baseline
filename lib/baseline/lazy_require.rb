# frozen_string_literal: true

module Baseline
  # Runs a configuration block the first time `require "<path>"` successfully
  # loads the given library. Lets you defer expensive gem loads until they're
  # actually used while still configuring them (API keys, etc.) in an initializer:
  #
  #   # config/initializers/stripe.rb
  #   Baseline::LazyRequire.on_first_require("stripe") do
  #     Stripe.api_key = Rails.application.env_credentials.stripe_api_key
  #   end
  #
  #   # at call sites
  #   require "stripe"
  #   Stripe::Payout.list(...)
  #
  # The path must match exactly what's passed to `require`; settle on the
  # library's canonical name.
  module LazyRequire
    @configs = {}

    class << self
      def on_first_require(path, &block)
        @configs[path] = block
      end

      def __pop(path) = @configs.delete(path)
    end

    module KernelExt
      private def require(path)
        loaded_now = super
        if loaded_now && (cb = ::Baseline::LazyRequire.__pop(path))
          cb.call
        end
        loaded_now
      end
    end

    ::Kernel.prepend KernelExt
  end
end
