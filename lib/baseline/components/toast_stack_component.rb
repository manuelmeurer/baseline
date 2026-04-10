# frozen_string_literal: true

module Baseline
  class ToastStackComponent < ViewComponent::Base
    renders_many :toasts, ToastComponent
  end
end
