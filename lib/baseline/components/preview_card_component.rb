# frozen_string_literal: true

module Baseline
  class PreviewCardComponent < ApplicationComponent
    def initialize(url)
      @url = url
      @id  = "preview-card-#{SecureRandom.hex(3)}"
    end

    def before_render
      require "baseline/services/external/link_metadata"

      @url         = helpers.normalize_url(@url)
      metadata     = External::LinkMetadata.get_metadata(@url, cache: 1.year)
      @title       = CGI.unescapeHTML(CGI.unescapeHTML(metadata.fetch(:title)))
      @description = CGI.unescapeHTML(CGI.unescapeHTML(metadata.fetch(:description)))
      @image_url   = CGI.unescapeHTML(metadata.deep_fetch(:image, :url))
      @website     = IdentifyURL.call(@url).name
    end
  end
end
