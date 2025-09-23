# frozen_string_literal: true

module Baseline
  module MailerHelper
    def wrapper(url: nil)
      link_or_spacer =
        tag.mj_section do
          tag.mj_column do
            if url
              render "baseline/mailers/view_in_browser", url:
            else
              tag.mj_spacer
            end
          end
        end

      wrapper =
        tag.mj_wrapper(border: "1px solid #e9e9e9", "background-color": "white", padding: 0) do
          yield
        end

      [
        link_or_spacer,
        wrapper
      ].join("\n").html_safe
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
