# frozen_string_literal: true

module Baseline
  module FramesControllable
    extend ActiveSupport::Concern

    included do
      allow_unauthenticated_access
      layout false
    end

    def show
      set_noindex_header

      template       = "web/frames/#{params[:id]}"
      _cache_objects = cache_objects

      return if fresh_when(
        _cache_objects,
        etag: [*_cache_objects, ::Current.user&.id],
        template:
      )

      begin
        render template
      rescue ActionView::MissingTemplate
        head :not_found
      end
    end

    private

      def action_i18n_scope
        super params[:id]
      end
  end
end
