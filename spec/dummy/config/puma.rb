# frozen_string_literal: true

threads 3, 3

port    ENV.fetch("PORT",    3000)
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

plugin :tmp_restart

# Recommendation from https://github.com/Shopify/autotuner
before_fork do
  3.times { GC.start }
  GC.compact
end
