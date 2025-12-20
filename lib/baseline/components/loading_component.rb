# frozen_string_literal: true

module Baseline
  class LoadingComponent < ApplicationComponent
    def initialize(message: NOT_SET, margin: true)
      @message, @margin = message, margin
    end

    def call
      if @message == NOT_SET
        @message = t(:please_wait)
      end

      safe_join([
        component(:icon, "spinner", version: :solid, class: "fa-pulse"),
        @message
      ], " ").then {
        tag.div _1, class: ("m-1" if @margin)
      }
    end
  end
end
