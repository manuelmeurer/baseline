# frozen_string_literal: true

module Baseline
  class Current < ActiveSupport::CurrentAttributes
    attribute :default_label_style,  default: :vertical
    attribute :default_button_color, default: :primary
    attribute :tailwind, default: false
  end
end
