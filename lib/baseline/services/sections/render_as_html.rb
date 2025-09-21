# frozen_string_literal: true

module Baseline
  module Sections
    class RenderAsHTML < ApplicationService
      INTERNAL_HOST_REGEX = %r{
        #{URLFormatValidator.regex}
        (\w+\.)?
        #{Rails.application.env_credentials.host!}
      }ix.freeze
      SLACK_CHANNEL_REGEX = /#([a-zäöü0-9-]+)/

      def call(section, debug: false)
        if section.persisted?
          cache_key = [
            :section_html,
            section
          ]

          Rails.cache.fetch(cache_key) do
            generate section, debug
          end
        else
          generate section, debug
        end
      rescue => error
        if debug
          "Error rendering section: #{error.message} (#{error.class})"
        else
          raise error
        end
      end

      private

        def generate(section, debug)
          html = section.content_html

          (1..6)
            .map { "h#{_1}" }
            .join(", ")
            .then { html.css _1 }
            .each {
              _1[:id] = _1.content.parameterize
            }

          html.css("a").each do |link|
            unless link[:href].match?(INTERNAL_HOST_REGEX)
              ApplicationController.helpers.external_link_attributes.each do |key, value|
                link[key] = value
              end
            end
          end

          html.css("table").each do |table|
            table.add_class %w[table table-striped]
          end

          html.css("blockquote").each do |table|
            table.add_class %w[blockquote]
          end

          html.traverse do |node|
            next unless node.text?

            case
            when node.content.match?(SLACK_CHANNEL_REGEX)
              new_content = node.content.gsub(SLACK_CHANNEL_REGEX) do |match|
                channel_name = match[SLACK_CHANNEL_REGEX, 1]
                SlackChannel.find_public_by_normalized_or_previous_name!(channel_name)
              rescue ActiveRecord::RecordNotFound
                match
              else
                link_to match,
                  web_slack_channel_url(SlackChannel.normalize_name(channel_name)),
                  **ApplicationController.helpers.external_link_attributes
              end
              unless new_content == node.content
                node.replace Nokogiri::HTML.fragment(new_content)
              end
            when keyword = node.content[/\A\s*(EMBED|BUTTON)\s*\z/, 1]&.downcase&.to_sym
              link = node.next

              unless link&.name == "a"
                raise Error, "Expected a link next to the EMBED keyword but found: #{link&.name || "nothing"}"
              end

              case keyword
              when :embed
                embed = ApplicationController.render(
                  partial: "shared/iframely_embed",
                  locals:  { url: link[:href] }
                )
                node.after tag.div(class: "mt-3 mb-3") { embed }
                if link.next&.name == "br"
                  link.next.remove
                end
                link.remove
              when :button
                link.add_class %w[btn btn-outline-primary]
              else
                raise Error, "Unexpected keyword: #{keyword}"
              end

              node.remove
            end
          end

          tag.div id: section.slug do
            [
              section.headline&.then { tag.h2 _1, id: _1.parameterize },
              html.to_s
            ].compact
              .join("\n")
              .html_safe
          end
        end
    end
  end
end
