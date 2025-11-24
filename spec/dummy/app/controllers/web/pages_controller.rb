# frozen_string_literal: true

module Web
  class PagesController < BaseController
    PAGES = %w[
      home
    ].freeze

    def show
      expires_soon

      render "web/pages/#{params[:id]}",
        formats: :html
    end

    private

      def action_i18n_scope
        super params[:id].tr("-", "_")
      end

      _baseline_finalize
  end
end
