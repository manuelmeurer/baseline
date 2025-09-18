# frozen_string_literal: true

# Based on https://github.com/soundasleep/html2text_ruby
module Baseline
  module Converters
    class HTMLToText < ApplicationService
      DO_NOT_TOUCH_WHITESPACE = "<do-not-touch-whitespace>".freeze

      def call(html)
        cache_key = [
          :html_to_text,
          ActiveSupport::Digest.hexdigest(html)
        ]

        Rails.cache.fetch cache_key do
          generate(html)
        end
      end

      private

        def generate(html)
          require "nokogiri"

          if html.exclude?("<html")
            # Stop Nokogiri from inserting in <p> tags
            html = "<div>#{html}</div>"
          end

          html = fix_newlines(replace_entities(html))
          html = remove_keywords(html)

          Nokogiri::HTML
            .fragment(html)
            .then { iterate_over(_1) }
            .then { remove_leading_and_trailing_whitespace(_1) }
            .then { remove_unnecessary_empty_lines(_1) }
            .chomp
        end

        def fix_newlines(text)
          text
            .gsub("\r\n", "\n")
            .gsub("\r", "\n")
        end

        def replace_entities(text)
          text
            .gsub("&nbsp;", " ")
            .gsub("\u00a0", " ")
            .gsub("&zwnj;", "")
        end

        def remove_keywords(text)
          text.gsub(%r{\b(SMALL|BUTTON|EMBED)\b\s+}, "")
        end

        def remove_leading_and_trailing_whitespace(text)
          # ignore any <pre> blocks, which we don't want to interact with
          pre_blocks = text.split(DO_NOT_TOUCH_WHITESPACE)

          output = []
          pre_blocks.each.with_index do |block, index|
            if index % 2 == 0
              output << block.gsub(/[ \t]*\n[ \t]*/im, "\n").gsub(/ *\t */im, "\t")
            else
              output << block
            end
          end

          output.join("")
        end

        def remove_unnecessary_empty_lines(text)
          text.gsub(/\n\n\n*/im, "\n\n")
        end

        def trimmed_whitespace(text)
          # Replace whitespace characters with a space (equivalent to \s)
          # and force any text encoding into UTF-8
          if text.valid_encoding?
            text.gsub(/[\t\n\f\r ]+/im, " ")
          else
            text
              .force_encoding("WINDOWS-1252")
              .encode("UTF-16be", invalid: :replace, replace: "?")
              .encode("UTF-8")
              .then { trimmed_whitespace _1 }
          end
        end

        def iterate_over(node)
          return "\n" if node.name.downcase == "br" && next_node_is_text?(node)

          return trimmed_whitespace(node.text) if node.text?

          if ["style", "head", "title", "meta", "script"].include?(node.name.downcase)
            return ""
          end

          if node.name.downcase == "pre"
            return "\n#{DO_NOT_TOUCH_WHITESPACE}#{node.text}#{DO_NOT_TOUCH_WHITESPACE}"
          end

          output = []

          output << prefix_whitespace(node)
          output += node.children.map do |child|
            if !child.name.nil?
              iterate_over(child)
            end
          end
          output << suffix_whitespace(node)

          output = output.compact.join("") || ""

          if !node.name.nil?
            if node.name.downcase == "a"
              output = wrap_link(node, output)
            elsif node.name.downcase == "img"
              output = image_text(node)
            end
          end

          output
        end

        def prefix_whitespace(node)
          case node.name.downcase
          when "hr"
            "\n---------------------------------------------------------------\n"
          when "h1", "h2", "h3", "h4", "h5", "h6", "ol", "ul"
            "\n\n"
          when "p"
            "\n\n"
          when "tr"
            "\n"
          when "div"
            if node.parent.name == "div" && (node.parent.text.strip == node.text.strip)
              ""
            else
              "\n"
            end
          when "td", "th"
            "\t"
          when "li"
            "- "
          end
        end

        def suffix_whitespace(node)
          case node.name.downcase
          when "h1", "h2", "h3", "h4", "h5", "h6", "p"
            "\n\n"
          when "br"
            if next_node_name(node) != "div" && next_node_name(node)
              "\n"
            end
          when "li"
            "\n"
          when "div"
            if next_node_is_text?(node)
              "\n"
            elsif next_node_name(node) != "div" && next_node_name(node)
              "\n"
            end
          end
        end

        # links are returned in [text](link) format
        def wrap_link(node, output)
          href = node.attribute("href")
          name = node.attribute("name")

          output = output.strip

          # remove double [[ ]]s from linking images
          if output[0] == "[" && output[-1] == "]"
            output = output[1, output.length - 2]

            # for linking images, the title of the <a> overrides the title of the <img>
            if node.attribute("title")
              output = node.attribute("title").to_s
            end
          end

          # if there is no link text, but a title attr
          if output.empty? && node.attribute("title")
            output = node.attribute("title").to_s
          end

          if href.nil?
            if !name.nil?
              output = "[#{output}]"
            end
          else
            href = href.to_s

            if href != output &&
              href != "mailto:#{output}" &&
              href != "http://#{output}" &&
              href != "https://#{output}"

              output = output.empty? ?
                      href :
                      "[#{output}](#{href})"
            end
          end

          if next_node_name(node).in?(%w[h1 h2 h3 h4 h5 h6])
            output += "\n"
          end

          output
        end

        def image_text(node)
          %w[title alt].map { node.attribute(_1).presence }
            .compact
            .first
            &.then { "[#{_1}]" }
        end

        def next_node_name(node)
          next_node = node.next_sibling

          while next_node
            break if next_node.element?
            next_node = next_node.next_sibling
          end

          if next_node && next_node.element?
            next_node.name.downcase
          end
        end

        def next_node_is_text?(node)
          !node.next_sibling.nil? &&
            node.next_sibling.text? &&
            !node.next_sibling.text.strip.empty?
        end

        def previous_node_name(node)
          previous_node = node.previous_sibling

          while previous_node
            break if previous_node.element?
            previous_node = previous_node.previous_sibling
          end

          if previous_node && previous_node.element?
            previous_node.name.downcase
          end
        end

        def previous_node_is_text?(node)
          !node.previous_sibling.nil? &&
            node.previous_sibling.text? &&
            !node.previous_sibling.text.strip.empty?
        end
    end
  end
end
