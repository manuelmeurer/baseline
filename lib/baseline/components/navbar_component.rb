# frozen_string_literal: true

module Baseline
  class NavbarComponent < ApplicationComponent
    renders_many :groups, "GroupComponent"

    def initialize(
      container:     :lg,
      expand:        :lg,
      brand:         nil,
      brand_url:     "/",
      bg:            :body_tertiary,
      border_bottom: true,
      css_class:     nil,
      data:          nil,
      sticky:        nil,
      fixed:         nil)

      @id = "navbar-collapsable"

      @brand, @brand_url, @css_class, @data =
        brand, brand_url, Array(css_class), data

      if bg
        @css_class << "bg-#{bg.dasherize}"
      end

      if border_bottom
        @css_class << "border-bottom"
      end

      %i[sticky fixed].each do |position|
        next unless value = binding.local_variable_get(position)
        unless value.try(:to_sym).in?(%i[top bottom])
          raise "#{position} must be 'top' or 'bottom', got: #{value}"
        end
        @css_class << "#{position}-#{value}"
        break
      end

      if expand
        [
          "navbar-expand",
          (expand unless expand == true)
        ].compact
          .join("-")
          .then {
            @css_class << _1
          }
      end

      @container_css_class = if container
        [
          "container",
          (container unless container == true)
        ].compact
          .join("-")
      end
    end

    def auth_group
      with_group do |group|
        unless ::Current.userable&.then { _1.class.to_s == ::Current.userable_class }
          next group.with_item_link([::Current.namespace, :login]) do
            safe_join [
              component(:icon, "sign-in", fixed_width: true, class: "me-1"),
              "Login"
            ], " "
          end
        end

        avatar_and_name = safe_join([
          helpers.attachment_image_tag(::Current.userable.photo_or_dummy, :sm_thumb),
          ::Current.userable.first_name,
          nil # Make sure there's whitespace after the name, so that there is some margin to the dropdown toggle icon.
        ], " ")

        group.with_item_dropdown(avatar_and_name, css_class: "avatar", align_end: true) do |dropdown|
          dropdown.with_item_link([::Current.namespace, :logout], data: { turbo_method: :delete }) do
            safe_join [
              component(:icon, "sign-out", fixed_width: true, class: "me-1"),
              "Log out"
            ], " "
          end
        end
      end
    end

    class GroupComponent < ApplicationComponent
      renders_many :items,
        types: %i[link dropdown content].index_with {
          "#{name.deconstantize}::#{_1.camelize}Component"
        }

      attr_reader :css_class

      def initialize(css_class: nil)
        @css_class = css_class
      end

      def call; end
    end

    class ContentComponent < ApplicationComponent
      def call = content
    end

    class LinkComponent < ApplicationComponent
      include ActsAsLinkComponent

      # For some reason, this is necessary, otherwise ActsAsLinkComponent#call is not called.
      def call = super

      private

        def wrapper
          tag.li class: "nav-item" do
            yield
          end
        end

        def css_class    = "nav-link"
        def aria_current = "page"
    end

    class DropdownComponent < ApplicationComponent
      renders_many :items,
        types: %i[link divider content].index_with {
          "#{_1.camelize}Component"
        }

      def initialize(label, align_end: false, align_start: false, css_class: nil)
        @label, @align_end, @align_start =
          label, align_end, align_start
        @css_class = Array(css_class).append("nav-item", "dropdown")
      end

      def call
        case
        when items.none?
          raise "No items found."
        when items.any? { _1.instance_variable_get(:@__vc_component_instance).is_a?(ContentComponent) }
          if items.many?
            raise "If a content component is defined for a dropdown, it must be the only component."
          end
          dropdown_element = :div
        else
          dropdown_element = :ul
        end

        dropdown_css_class = %w[dropdown-menu]

        {
          end:   @align_end,
          start: @align_start
        }.compact_blank
          .each do |suffix, value|
            [
              "dropdown-menu",
              (value unless value == true),
              suffix
            ].compact_blank
              .join("-")
              .then {
                dropdown_css_class << _1
              }
          end

        tag.li(class: @css_class) do
          link_to(
            @label,
            "#",
            class:         "nav-link dropdown-toggle",
            role:          "button",
            data:          { bs_toggle: "dropdown" },
            aria_expanded: "false"
          ) +
          tag.public_send(dropdown_element, class: dropdown_css_class) do
            safe_join items
          end
        end
      end

      class ContentComponent < ApplicationComponent
        def call = content
      end

      class LinkComponent < ApplicationComponent
        include ActsAsLinkComponent

        # For some reason, this is necessary, otherwise ActsAsLinkComponent#call is not called.
        def call = super

        private

          def wrapper
            tag.li class: "nav-item" do
              yield
            end
          end

          def css_class    = "dropdown-item"
          def aria_current = "true"
      end

      class DividerComponent < ApplicationComponent
        def call
          tag.li do
            tag.hr(class: "dropdown-divider")
          end
        end
      end
    end
  end
end
