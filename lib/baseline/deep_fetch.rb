# frozen_string_literal: true

module DeepFetch
  def deep_fetch(*keys, &block)
    keys.inject(self) {
      _1.fetch(_2)
    }
  rescue KeyError => error
    if block_given?
      block.call
    else
      raise error
    end
  end
end

class Hash
  include DeepFetch
end

if defined?(ActionController::Parameters)
  class ActionController::Parameters
    include DeepFetch
  end
end
