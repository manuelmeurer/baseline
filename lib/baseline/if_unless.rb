# frozen_string_literal: true

class Object
  def if(condition, action = nil, _unless: false, &block)
    result = case condition
      when Proc  then condition.call(self)
      when Class then self.is_a?(condition)
      else condition
      end

    if _unless
      result = !result
    end

    return self unless result

    if action
      if block
        raise "You can't pass both a block and an action."
      end
      action
    else
      args = block.arity < 0 ?
        [self] :
        [self, result].take(block.arity)
      block.call *args
    end
  end

  def unless(*, &block)
    self.if(*, _unless: true, &block)
  end
end
