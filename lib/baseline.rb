module Baseline
  NoBackgroundProcessorFound = Class.new(StandardError)
  RedisNotFound              = Class.new(StandardError)

  class << self
    def redis
      @redis ||= configuration.redis || (defined?(Kredis) && Kredis.redis) \
        or raise RedisNotFound, "Redis not configured."
    end

    def replace_records_with_global_ids(arg)
      method = method(__method__)

      case arg
      when Array then arg.map(&method)
      when Hash  then arg.transform_keys(&method)
                         .transform_values(&method)
      else arg.respond_to?(:to_global_id) ? "_#{arg.to_global_id.to_s}" : arg
      end
    end

    def replace_global_ids_with_records(arg)
      method = method(__method__)

      case arg
      when Array  then arg.map(&method)
      when Hash   then arg.transform_keys(&method)
                          .transform_values(&method)
      when String then (arg.starts_with?("_") && GlobalID::Locator.locate(arg[1..-1])) || arg
      else arg
      end
    end
  end
end

require "baseline/asyncable"
require "baseline/configuration"
require "baseline/helper"
require "baseline/model_extensions"
require "baseline/railtie"
require "baseline/service"
