# frozen_string_literal: true

class Object
  def if(condition, action = nil)
    result = condition.is_a?(Proc) ? condition.call(self) : condition
    return self unless result
    if action
      if block_given?
        raise "You can't pass both a block and an action."
      end
      action
    else
      yield self, result
    end
  end
end
