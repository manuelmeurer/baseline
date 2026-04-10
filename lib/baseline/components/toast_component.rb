# frozen_string_literal: true

module Baseline
  class ToastComponent < ApplicationComponent
    TYPES = {
      success: {
        icon: :accept,
        icon_color: "text-green-400"
      },
      error: {
        icon: :reject,
        icon_color: "text-red-400"
      },
      warning: {
        icon: :warning,
        icon_color: "text-yellow-400"
      },
      info: {
        icon: :info,
        icon_color: "text-blue-400"
      }
    }.freeze

    def initialize(type: :success, title: nil, body: nil, dismiss_after: 5000)
      @type, @title, @body, @dismiss_after =
        type, title, body, dismiss_after
      @icon, @icon_color = TYPES.fetch(type).values_at(:icon, :icon_color)
    end

    def before_render
      @stimco = helpers.stimco(:toast, to_h: false)
    end
  end
end
