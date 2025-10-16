# frozen_string_literal: true

module Baseline
  class LoadingComponent < ApplicationComponent
    def initialize(message: NOT_SET)
      @message = message
    end

    def call
      if @message == NOT_SET
        @message = t(:please_wait)
      end

      tag.div class: "m-1" do
        safe_join [
          component(:icon, "spinner", version: :solid, class: "fa-pulse"),
          @message
        ], " "
      end
    end
  end
end
