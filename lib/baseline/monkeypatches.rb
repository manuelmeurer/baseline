# frozen_string_literal: true

class Object
  def if(condition, action = nil, _unless: false, &block)
    result =
      case condition
      when Proc   then condition.call(self)
      when Class  then self.is_a?(condition)
      when Regexp then self.match(condition)
      else condition
      end

    if _unless
      result = !result
    end

    return self unless result

    case
    when action
      if block
        raise "You can't pass both a block and an action."
      end
      action
    when block
      args =
        block.arity < 0 ?
        [self] :
        [self, result].take(block.arity)
      block.call(*args)
    end
  end

  def unless(*, &)
    self.if(*, _unless: true, &)
  end

  def fetch_from(hash, &block)
    hash.fetch(self, &block)
  end
end

module I18n
  class << self
    def with_available_locales(&block)
      unless block
        return to_enum(__method__)
      end

      available_locales.each do |locale|
        with_locale locale do
          block.call locale
        end
      end
    end

    def other_locale
      available_locales
        .without(locale)
        .tap {
          unless _1.one?
            raise "Expected exactly one other locale, but got #{_1.size}."
          end
        }.first
    end
  end
end

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
