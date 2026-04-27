# frozen_string_literal: true

def load_seeds
  puts "Loading seeds..."

  # Admin users

  [
    %w[Manuel Meurer manuel@meurer.io]
  ].each do |first_name, last_name, email|
    next if AdminUser.with_email(email).exists?

    AdminUser.create!(
      first_name:,
      last_name:,
      email:
    )
  end

  # Subscriptions
  Subscription.create_all!
end

ENV["SEEDS"] = true.to_s

begin
  load_seeds
ensure
  ENV.delete "SEEDS"
end
