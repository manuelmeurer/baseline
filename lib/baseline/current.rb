# frozen_string_literal: true

class Baseline::Current < ActiveSupport::CurrentAttributes
  attribute :default_label_style,  default: :vertical
  attribute :default_button_color, default: :primary
end
