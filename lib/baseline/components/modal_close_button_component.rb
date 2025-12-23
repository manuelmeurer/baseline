# frozen_string_literal: true

module Baseline
  class ModalCloseButtonComponent < ApplicationComponent
    def initialize(wrapper: true, text: nil, icon: :reject, button_color: "outline-dark")
      @wrapper, @text, @icon, @button_color =
        wrapper, text, icon, button_color
    end

    def call
      return unless ::Current.modal_request

      @text ||= t(:cancel).capitalize

      link = link_to("#", class: "btn btn-#{@button_color}", data: { bs_dismiss: "modal" }) do
        safe_join [
          component(:icon, @icon),
          @text
        ], " "
      end

      if @wrapper
        tag.div class: "d-none", data: helpers.stimco(:modal, to_h: false).target(:footer_content) do
          link
        end
      else
        link
      end
    end
  end
end
