# frozen_string_literal: true

module Baseline
  module ActsAsLinkComponent
    def initialize(label_or_url, url = nil, css_class: nil, data: nil, modal: false, active: nil, collapsable: true)
      @label, @url =
        url ?
        [label_or_url, url] :
        [nil, label_or_url]
      @css_class, @data, @modal, @active, @collapsable =
        css_class, data, modal, active, collapsable
    end

    def collapsable? = @collapsable

    def call
      @url     = url_for(@url)
      @label ||= content
      @active  = current? if @active.nil?
      receiver, method =
        @modal ?
        [helpers, :link_to_modal] :
        [self,    :link_to]

      wrapper do
        receiver.public_send \
          method,
          @label,
          @url,
          class:        class_names(css_class, @css_class, active: @active),
          data:         @data,
          aria_current: (aria_current if current?)
        end
    end

    private

      def css_class = nil
      def wrapper   = yield

      def current?
        return false unless %w[/ http:// https://].any? { @url.start_with? _1 }

        current_url = helpers.request.original_url
        root_paths =
          helpers.try(:navbar_root_paths)&.map { url_for _1 } ||
          [url_for(helpers.prefix_namespace_unless_engine(:root))]

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
end
