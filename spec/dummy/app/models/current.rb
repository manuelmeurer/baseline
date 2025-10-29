# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :namespace, :action_name, :modal_request, :admin_user, :user

  def user=(value)
    super
    self.admin_user = value&.admin_user
  end
end
