# frozen_string_literal: true

module Baseline
  module NamespaceLayout
    extend ActiveSupport::Concern

    included do
      layout -> {
        if Current.try(:modal_request)
          break "modal"
        end

        request.xhr? ||
          request.format.text? ||
          request.format.xml?  ||
          request.format.ics?  ||
          turbo_frame_request? ||
          response.content_type&.downcase&.include?("turbo-stream") ?
            false :
            Current.namespace.to_s
      }
    end
  end
end
