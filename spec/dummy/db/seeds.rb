# frozen_string_literal: true

def load_seeds
  puts "Loading seeds..."

  # Subscriptions
  Subscription.create_all!
end

ENV["SEEDS"] = true.to_s

begin
  load_seeds
ensure
  ENV.delete "SEEDS"
end
