# frozen_string_literal: true

module Baseline
  class NavbarComponent < ApplicationComponent
    renders_many :groups, "GroupComponent"

    def initialize(
      container:     :lg,
      expand:        :lg,
      brand:         nil,
      brand_url:     "/",
      bg:            true,
      border_bottom: true,
      css_class:     nil,
      data:          nil,
      sticky:        nil,
      fixed:         nil)

      @brand, @brand_url, @css_class, @data =
        brand, brand_url, Array(css_class), data

      if Current.tailwind
        if bg == true
          bg = "bg-base-100"
        end

        if bg
          @css_class << bg
        end

        if border_bottom
          @css_class.push("border-b", "border-base-300")
        end

        %i[sticky fixed].each do |position|
          next unless value = binding.local_variable_get(position)
          unless value.try(:to_sym).in?(%i[top bottom])
            raise "#{position} must be 'top' or 'bottom', got: #{value}"
          end
          @css_class.push(position.to_s, "#{value}-0", "z-50")
          break
        end

        if container
          @css_class.push(
            "max-w-7xl", "mx-auto", "flex", "items-center"
          )
        end
      else
        @id = "navbar-collapsable"
        bg = "bg-body-tertiary" if bg == true
        @css_class << bg if bg
        @css_class << "border-bottom" if border_bottom

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
          ].compact.join("-")
        end
      end
    end

    def auth_group(namespace: ::Current.namespace, &block)
      with_group do |group|
        group.auth_item(namespace:, &block)
      end
    end

    private

      def tw_active_groups
        groups.select { _1.items.any? }
      end

      def render_tw_brand
        return unless @brand

        if @brand_url
          link_to @brand, @brand_url, class: "btn btn-ghost text-xl"
        else
          tag.span(@brand, class: "btn btn-ghost text-xl")
        end
      end

      def render_tw_hamburger
        collapsable = tw_active_groups.flat_map(&:collapsable_items)
        return if collapsable.empty?

        tag.div(class: "dropdown") do
          tag.div(tabindex: "0", role: "button", class: "btn btn-ghost lg:hidden") do
            tag.svg(xmlns: "http://www.w3.org/2000/svg", fill: "none", viewbox: "0 0 24 24", stroke: "currentColor", class: "h-5 w-5") do
              tag.path("", stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M4 6h16M4 12h8m-8 6h16")
            end
          end +
          tag.ul(tabindex: "0", class: "menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow") do
            safe_join collapsable
          end
        end
      end

      def render_tw_group_items(group)
        parts = []

        if group.collapsable_items.any?
          parts << tag.ul(class: "menu menu-horizontal px-1 hidden lg:flex") {
            safe_join group.collapsable_items
          }
        end

        if group.non_collapsable_items.any?
          parts << tag.ul(class: "menu menu-horizontal px-1") {
            safe_join group.non_collapsable_items
          }
        end

        safe_join parts
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

      def auth_item(namespace: ::Current.namespace)
        if ::Current.user
          photo = component(:attachment_image, ::Current.user.photo_or_dummy, :sm_thumb)

          if Current.tailwind
            avatar = tag.div(class: "avatar") do
              tag.div(class: "w-10 rounded-full") { photo }
            end
          else
            avatar = photo
          end

          avatar_and_name = safe_join([
            avatar,
            ::Current.user.first_name,
            nil # Make sure there's whitespace after the name, so that there is some margin to the dropdown toggle icon.
          ], " ")

          css_class = "avatar" unless Current.tailwind

          with_item_dropdown(avatar_and_name, css_class: css_class, align_end: true, collapsable: false) do |dropdown|
            yield dropdown if block_given?
            dropdown.with_item_link([namespace, :logout], data: { turbo_method: :delete }) do
              safe_join [
                component(:icon, "sign-out", fixed_width: true, class: "me-1"),
                t(:log_out, scope: :navbar)
              ], " "
            end
          end
        else
          with_item_content collapsable: false do
            link_to [namespace, :login, only_path: false], class: "btn btn-outline-light login" do
              t :login, scope: :navbar
            end
          end
        end
      end

      def collapsable_items
        items.select { _1.instance_variable_get(:@__vc_component_instance).collapsable? }
      end

      def non_collapsable_items
        items.reject { _1.instance_variable_get(:@__vc_component_instance).collapsable? }
      end

      def call; end
    end

    class ContentComponent < ApplicationComponent
      def initialize(collapsable: true)
        @collapsable = collapsable
      end

      def collapsable? = @collapsable
      def call = content
    end

    class LinkComponent < ApplicationComponent
      include ActsAsLinkComponent

      # For some reason, this is necessary, otherwise ActsAsLinkComponent#call is not called.
      def call = super

      private

        def wrapper
          tag.li(class: (Current.tailwind ? nil : "nav-item")) { yield }
        end

        def css_class    = Current.tailwind ? nil : "nav-link"
        def aria_current = "page"
    end

    class DropdownComponent < ApplicationComponent
      renders_many :items,
        types: %i[link divider content].index_with {
          "#{_1.camelize}Component"
        }

      def initialize(label, align_end: false, align_start: false, css_class: nil, collapsable: true)
        @label, @align_end, @align_start, @collapsable =
          label, align_end, align_start, collapsable

        @css_class = if Current.tailwind
          Array(css_class)
        else
          Array(css_class).append("nav-item", "dropdown")
        end
      end

      def collapsable? = @collapsable

      def call
        raise "No items found." if items.none?

        Current.tailwind ? call_tailwind : call_bootstrap
      end

      private

      def call_tailwind
        tag.li class: @css_class do
          tag.details do
            tag.summary(@label) +
            tag.ul(class: "p-2") {
              safe_join items
            }
          end
        end
      end

      def call_bootstrap
        case
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

      public

      class ContentComponent < ApplicationComponent
        def call = content
      end

      class LinkComponent < ApplicationComponent
        include ActsAsLinkComponent

        # For some reason, this is necessary, otherwise ActsAsLinkComponent#call is not called.
        def call = super

        private

          def wrapper
            tag.li(class: (Current.tailwind ? nil : "nav-item")) { yield }
          end

          def css_class    = Current.tailwind ? nil : "dropdown-item"
          def aria_current = "true"
      end

      class DividerComponent < ApplicationComponent
        def call
          if Current.tailwind
            tag.li(class: "divider")
          else
            tag.li { tag.hr(class: "dropdown-divider") }
          end
        end
      end
    end
  end
end
