# frozen_string_literal: true

module Baseline
  module Sections
    class RenderAsMJML < ApplicationService
      KEYWORDS = %w[
        BUTTON
        EMBED
        SMALL
      ].freeze

      def call(section, debug: false)
        @section, @debug = section, debug

        if section.persisted?
          cache_key = [
            :section_mjml,
            section
          ]

          Rails.cache.fetch(cache_key) do
            generate
          end
        else
          generate
        end
      rescue => error
        if debug
          tag.mj_text "Error rendering section: #{error.message} (#{error.class})"
        else
          raise error
        end
      end

      private

        def generate
          html = @section.content_html

          [
            @section.headline&.then { tag.mj_text _1, "mj-class": "h1" },
            *process(html.children)
          ].compact
            .join("\n")
            .html_safe
        rescue => error
          if @debug
            tag.mj_text "Error rendering section: #{error.message} (#{error.class})"
          else
            raise error
          end
        end

        def process(elements)
          return [] if elements.empty?

          tags = []

          if text_elements = elements.take_while {
              _1.name.in?(%w[text span a strong em]) ||
                (_1.name == "br" && !(elements[elements.index(_1) + 1]&.name == "br"))
            }.presence

            elements = elements[text_elements.size..-1]

            # Drop leading and training <br> elements
            text_elements.shift while text_elements.any? && insignificant_element(text_elements.first)
            text_elements.pop   while text_elements.any? && insignificant_element(text_elements.last)

            if text_elements.any?
              keyword = text_elements
                .first
                .then { _1.content.strip.split.first if _1.text? }
                &.then { _1 if _1.in?(KEYWORDS) }

              case
              when keyword
                new_tags = send("generate_#{keyword.downcase}_tags", text_elements)
                tags.concat Array(new_tags)
              when text_content = text_elements
                .map { _1.name == "text" ? _1.content : _1.to_s }
                .compact_blank
                .join(" ")
                .presence

                tags << tag.mj_text(text_content.html_safe)
              end
            end
          else
            element = elements.shift

            mj_text_params =
              case element.name
              when "blockquote" then { "font-style": "italic", "padding-left": "30px" }
              when /\Ah[123]\z/ then { "mj-class": element.name }
              end

            new_tags =
              if mj_text_params
                element.inner_html.presence&.then { tag.mj_text _1.html_safe, **mj_text_params }
              else
                case element.name
                when "br", "comment" # ignore
                when "img"
                  url = Addressable::URI.parse(element[:src]).tap do |uri|
                    uri.scheme ||= "https"
                    uri.host   ||= Addressable::URI.parse(Rails.application.config.asset_host).host
                  end.to_s
                  tag.mj_image src: url
                when "ul", "ol"
                  tag.mj_text element.to_s.html_safe
                when "hr"
                  tag.mj_divider
                when "b"
                  tag.mj_text element.to_s.html_safe, "mj-class": "bold"
                when "p", "div", "action-text-attachment", "figure", "pre"
                  send __method__, element.children
                else raise "Unexpected element: #{element.name}"
                end
              end

            tags.concat(Array(new_tags))
          end

          tags.concat process(elements)
        end

        def generate_embed_tags(elements)
          text = elements.first.try(:content).try(:strip)
          unless text == "EMBED"
            raise Error, "Expected first element to contain only the EMBED keyword but found: #{text}"
          end

          unless elements.size == 2 && elements.last.name == "a"
            raise Error, "Expected exactly two elements and the last one should be a link, but found #{elements.size}: #{elements.inspect}"
          end

          require "baseline/services/external/browser_screenshot"

          url = elements.last[:href]
          html = ApplicationController.render(
            partial: "baseline/preview_card_page",
            locals:  { url: }
          )
          image_url = External::BrowserScreenshot.generate(html, locator: "body > a")

          tag.mj_image(src: image_url, href: url)
        end

        def generate_button_tags(elements)
          text = elements.first.try(:content).try(:strip)
          unless text == "BUTTON"
            raise Error, "Expected first element to contain only the BUTTON keyword but found: #{text}"
          end

          unless elements.size == 2 && elements.last.name == "a"
            raise Error, "Expected exactly two elements and the last one should be a link, but found #{elements.size}: #{elements.inspect}"
          end

          link = elements.last
          tag.mj_button href: link[:href], "mj-class": "primary" do
            link.content
          end
        end

        def generate_small_tags(elements)
          elements.first.content = elements.first.text.sub(/\A\s*SMALL\s+/, "")

          tag.mj_text "mj-class": "small" do
            process(elements).join("\n").html_safe
          end
        end

        def insignificant_element(element)
          element.name == "br" || (element.text? && element.content.blank?)
        end
    end
  end
end
