# frozen_string_literal: true

module Baseline
  class Current < ActiveSupport::CurrentAttributes
    attribute :default_label_style,  default: :vertical
    attribute :default_button_color, default: :primary
    attribute :tailwind,             default: false
    attribute :namespace,
              :action_name,
              :modal_request,
              :drawer_request
  end
end
