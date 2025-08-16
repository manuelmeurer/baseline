# frozen_string_literal: true

module Baseline
  module NamespaceLayout
    extend ActiveSupport::Concern

    included do
      layout -> {
        if ::Current.try(:modal_request)
          break "modal"
        end

        break false if
          request.xhr? ||
          request.format.text? ||
          request.format.xml?  ||
          request.format.ics?  ||
          turbo_frame_request? ||
          response.content_type&.downcase&.include?("turbo-stream")

        if ::Current.namespace.blank?
          raise "Current namespace not set."
        end

        ::Current.namespace.to_s
      }
    end
  end
end
