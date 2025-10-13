# frozen_string_literal: true

module Baseline
  module MailerHelper
    def wrapper
      link_or_spacer =
        tag.mj_section do
          tag.mj_column do
            if @email_delivery&.web_url
              render "baseline/mailers/view_in_browser"
            else
              tag.mj_spacer
            end
          end
        end

      wrapper =
        tag.mj_wrapper(border: "1px solid #e9e9e9", "background-color": "white", padding: 0) do
          yield
        end

      safe_join [
        link_or_spacer,
        wrapper
      ], "\n"
    end

    def header_image(url, **args)
      if href = args[:href]
        args[:href] = url_for(href)
      end

      tag.mj_section padding: 0 do
        tag.mj_column do
          tag.mj_image src: url, **args
        end
      end
    end

    def sections(sections)
      sections
        .flat_map {
          _1._do_render_as_mjml(debug: !!@debug_sections)
        }.compact
        .join("\n#{tag.mj_divider}\n")
        .html_safe
    end
  end
end
