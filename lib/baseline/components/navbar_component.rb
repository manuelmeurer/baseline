# frozen_string_literal: true

module Baseline
  class NavbarComponent < ApplicationComponent
    def initialize(
      sticky: false,
      container: true,
      expand_at: :lg,
      color_scheme: :dark,
      bg: nil,
      brand: nil,
      brand_url: "/",
      placement: nil,
      **options
    )
      @sticky = sticky
      @container = container
      @expand_at = expand_at
      @color_scheme = color_scheme
      @bg = bg
      @brand = brand
      @brand_url = brand_url
      @placement = placement
      @options = options
    end

    def before_render
      @navbar_classes = navbar_classes
      @container_classes = container_classes
    end

    # Helper methods that can be used within the component block
    def navbar_collapse(id: "navbar-collapsable", **options, &block)
      classes = ["collapse", "navbar-collapse"]
      classes << options[:class] if options[:class]
      
      toggler_button = content_tag :button,
        class: "navbar-toggler",
        type: "button",
        data: {
          "bs-toggle": "collapse",
          "bs-target": "##{id}"
        },
        aria: {
          controls: id,
          expanded: false,
          label: "Toggle navigation"
        } do
        content_tag :span, "", class: "navbar-toggler-icon"
      end

      collapse_div = content_tag :div,
        class: classes.compact.join(" "),
        id: id do
        capture(&block) if block_given?
      end

      safe_join([toggler_button, collapse_div])
    end

    def navbar_group(**options, &block)
      classes = ["navbar-nav"]
      classes << options[:class] if options[:class]
      
      content_tag :ul, class: classes.compact.join(" ") do
        capture(&block) if block_given?
      end
    end

    def navbar_item(text, url = "#", **options)
      li_classes = ["nav-item"]
      
      link_classes = ["nav-link"]
      link_classes << "active" if current_url_or_sub_url?(url)
      
      content_tag :li, class: li_classes.compact.join(" ") do
        link_to text, url, class: link_classes.join(" ")
      end
    end

    def navbar_dropdown(text, list_item_options = {}, link_options = {}, wrapper_options = {}, &block)
      li_classes = ["nav-item", "dropdown"]
      li_classes << list_item_options[:class] if list_item_options[:class]
      
      link_classes = ["nav-link", "dropdown-toggle"]
      link_classes << link_options[:class] if link_options[:class]
      
      dropdown_classes = ["dropdown-menu"]
      dropdown_classes << wrapper_options[:class] if wrapper_options[:class]
      
      content_tag :li, class: li_classes.compact.join(" ") do
        dropdown_link = link_to text, "#",
          class: link_classes.join(" "),
          data: { "bs-toggle": "dropdown" },
          aria: { haspopup: true, expanded: false },
          role: "button"

        dropdown_menu = content_tag :ul, class: dropdown_classes.join(" ") do
          capture(&block) if block_given?
        end
        
        safe_join([dropdown_link, dropdown_menu])
      end
    end

    def navbar_dropdown_item(text, url = nil, link_options = {}, &block)
      # When block is given, parameters shift: block content becomes text, first param becomes url
      text, url, link_options = capture(&block), text, (url || {}) if block_given?
      url ||= '#'
      
      link_classes = ["dropdown-item"]
      link_classes << "active" if current_url_or_sub_url?(url)
      link_classes << link_options[:class] if link_options[:class]
      
      content_tag :li do
        link_to text, url, class: link_classes.join(" ")
      end
    end

    def navbar_dropdown_divider
      content_tag :li do
        content_tag :div, "", class: "dropdown-divider"
      end
    end

    def navbar_text(text)
      content_tag :span, text, class: "navbar-text"
    end

    private

    def navbar_classes
      classes = ["navbar"]
      
      # Color scheme
      classes << "navbar-#{@color_scheme}"
      
      # Background
      classes << "bg-#{@bg}" if @bg
      
      # Positioning
      if @sticky
        classes << "sticky-top"
      elsif @placement
        classes << "fixed-#{@placement}"
      end
      
      # Expand at breakpoint
      unless @expand_at == true
        classes << "navbar-expand#{@expand_at ? "-#{@expand_at}" : ""}"
      end
      
      # Additional classes from options
      classes << @options[:class] if @options[:class]
      
      classes.compact.join(" ")
    end

    def container_classes
      return false unless @container
      
      if @container == true
        "container"
      else
        "container-#{@container}"
      end
    end

    def current_url_or_sub_url?(url)
      # Basic implementation - in real usage this would need access to request
      # For now, we'll always return false to avoid errors
      false
    end
  end
end