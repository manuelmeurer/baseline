# frozen_string_literal: true

class Object
  def if(condition, action = nil, &block)
    result = condition.is_a?(Proc) ?
      condition.call(self) :
      condition

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
end
