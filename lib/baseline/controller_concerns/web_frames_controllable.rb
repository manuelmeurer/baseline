# frozen_string_literal: true

module Baseline
  module WebFramesControllable
    extend ActiveSupport::Concern

    included do
      layout false
    end

    def show
      set_noindex_header

      template       = "web/frames/#{params[:id]}"
      _cache_objects = cache_objects

      return if fresh_when(
        _cache_objects,
        etag: [*_cache_objects, ::Current.user&.id], # führt das "*" nicht dazu, dass der AR scope mit "select *" ausgeführt wird, anstatt nur mit count, wie wir es wollen?
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
