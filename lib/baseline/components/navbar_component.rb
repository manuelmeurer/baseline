# frozen_string_literal: true

module Baseline
  class NavbarComponent < ApplicationComponent
    module ActsAsLinkComponent
      def initialize(label_or_url, url = nil, css_class: nil, data: nil, title: nil, replace_link_css_class: nil)
        @label, @url =
          url ?
          [label_or_url, url] :
          [nil, label_or_url]
        @css_class = Array(css_class).append("nav-item")
        @data, @replace_link_css_class = data, replace_link_css_class
      end

      def call
        @url = url_for(@url)
        @label ||= content

        tag.li(class: @css_class) do
          link_to \
            @label,
            @url,
            class:        @replace_link_css_class || class_names(link_css_class, active: current?),
            data:         @data,
            title:        @title,
            aria_current: (aria_current if current?)
         end
      end

      private def current?
        return false unless %w[/ http:// https://].any? { @url.start_with? _1 }

        current_url = helpers.request.original_url
        root_paths =
          helpers.try(:navbar_root_paths)&.map { url_for _1 } ||
          [url_for([::Current.namespace, :root])]

        cache_key = [
          @url,
          current_url,
          *root_paths
        ]

        Rails.cache.fetch(cache_key) do
          uri, current_uri = [
            @url,
            current_url
          ].map {
            URI.parse(it).tap {
              _1.query = nil
            }
          }
          break false if uri.host&.then { _1 != current_uri.host }
          normalized_path, normalized_current_path =
            [uri, current_uri].map do |uri|
              uri.path.chomp("/")
            end
          normalized_root_paths = root_paths.map { _1.chomp("/") }

          # If the URL is one of the root URLS, it's only current if it matches one of them exactly.
          # Otherwise it's also current if we're on a sub URL.
          if normalized_root_paths.include?(normalized_path)
            normalized_current_path == normalized_path
          else
            normalized_current_path.match? \
              %r{\A#{Regexp.escape(normalized_path)}\b}
          end
        end
      end
    end

    renders_many :groups, "GroupComponent"

    def initialize(
      container:     :lg,
      expand:        :lg,
      brand:         nil,
      brand_url:     "/",
      bg:            :body_tertiary,
      border_bottom: true,
      css_class:     nil,
      sticky:        nil,
      fixed:         nil)

      @id = "navbar-collapsable"

      @brand, @brand_url, @css_class =
        brand, brand_url, Array(css_class)

      if bg
        @css_class << "bg-#{bg.to_s.dasherize}"
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

    class GroupComponent < ApplicationComponent
      renders_many :items,
        types: %i[link dropdown].index_with {
          "#{name.deconstantize}::#{_1.to_s.camelize}Component"
        }

      attr_reader :css_class

      def initialize(css_class: nil)
        @css_class = css_class
      end

      def call; end
    end

    class LinkComponent < ApplicationComponent
      include ActsAsLinkComponent

      # For some reason, this is necessary, otherwise ActsAsLinkComponent#call is not called.
      def call = super

      private

        def link_css_class = "nav-link"
        def aria_current   = "page"
    end

    class DropdownComponent < ApplicationComponent
      renders_many :items,
        types: %i[link divider].index_with {
          "#{_1.to_s.camelize}Component"
        }

      def initialize(label, align_end: false, align_start: false, css_class: nil)
        @label, @align_end, @align_start =
          label, align_end, align_start
        @css_class = Array(css_class).append("nav-item", "dropdown")
      end

      def call
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
          tag.ul(class: dropdown_css_class) do
            safe_join items
          end
        end
      end

      class LinkComponent < ApplicationComponent
        include ActsAsLinkComponent

        # For some reason, this is necessary, otherwise ActsAsLinkComponent#call is not called.
        def call = super

        private

          def link_css_class = "dropdown-item"
          def aria_current   = "true"
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
