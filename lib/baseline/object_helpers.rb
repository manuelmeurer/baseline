# frozen_string_literal: true

class Object
  def if(condition, action = nil, _unless: false, &block)
    result = case condition
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
      args = block.arity < 0 ?
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
