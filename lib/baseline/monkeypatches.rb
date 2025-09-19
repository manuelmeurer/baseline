# frozen_string_literal: true

class Object
  def if(condition = Baseline::NOT_SET, action = nil, _unless: false, &block)
    if condition == Baseline::NOT_SET
      condition = block.call(self)
      block = nil
    end

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
            raise "Expected exactly one other locale, but got #{_1.size}: #{_1}"
          end
        }.first
    end
  end
end

if defined?(GlobalID)
  class GlobalID
    find = :find!
    if respond_to?(find)
      raise "#{self}.#{find} already exists."
    end
    define_singleton_method find do |*args, **kwargs|
      find(*args, **kwargs) or
        raise ActiveRecord::RecordNotFound
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

class Symbol
  def method_missing(method, ...)
    to_s.respond_to?(method) ?
      to_s.public_send(method, ...).to_sym :
      super
  end
end

class Symbol
  DELEGATE_TO_STRING_METHODS = [
    %i[sub gsub delete_prefix delete_suffix].map { [_1, :"#{_1}!"] }
  ].flatten.freeze

  def method_missing(method, ...)
    return super unless delegate_to_string?(method)

    to_s
      .public_send(method, ...)
      .to_sym
  end

  def respond_to_missing?(method, include_private = false)
    delegate_to_string?(method) ||
      super
  end

  private def delegate_to_string?(method)
    method.in?(DELEGATE_TO_STRING_METHODS) ||
      (
        defined?(ActiveSupport::Inflector) &&
        ActiveSupport::Inflector.respond_to?(method)
      )
  end
end
