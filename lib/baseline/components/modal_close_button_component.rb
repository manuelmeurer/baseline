# frozen_string_literal: true

module Baseline
  class ModalCloseButtonComponent < ApplicationComponent
    def initialize(wrapper: true)
      @wrapper = wrapper
    end

    def call
      return unless ::Current.modal_request

      link = link_to("#", class: "btn btn-outline-dark", data: { bs_dismiss: "modal" }) do
        safe_join [
          component(:icon, :reject),
          t(:cancel).capitalize
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
