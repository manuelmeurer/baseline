# frozen_string_literal: true

module Baseline
  module FramesControllable
    extend ActiveSupport::Concern

    included do
      try :allow_unauthenticated_access
      layout false
    end

    def show
      set_noindex_header

      template = "web/frames/#{params[:id]}"

      return if fresh_when(
        cache_objects,
        etag: [*cache_objects, ::Current.user&.id],
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
