# frozen_string_literal: true

module Baseline
  class ShareButtonComponent < ApplicationComponent
    def initialize(
      url:,
      button_color: Current.default_button_color,
      button_size:  nil,
      title:        nil,
      text:         nil)

      @url, @button_color, @button_size, @title, @text =
        url, button_color, button_size, title, text
    end

    def before_render
      case @url
      when Array
        unless @url.last.is_a?(Hash)
          @url << {}
        end
        @url.last[:only_path] = false
        @url = url_for(@url)
      when Hash
        @url = url_for(**@url, only_path: false)
      end

      @button_classes      = class_names("btn", "btn-#{@button_color}", "btn-#{@button_size}" => @button_size)
      @clipboard_stimco    = helpers.stimco(:copy_to_clipboard, text: @url, to_h: false)
      @tooltip_stimco      = helpers.stimco(:tooltip, options: { trigger: "click", placement: "bottom" })
      @share_button_stimco = helpers.stimco(:share_button, values: { url: @url, title: @title, text: @text }.compact, to_h: false)
    end
  end
end
