# frozen_string_literal: true

module Baseline
  module ErrorsControllable
    extend ActiveSupport::Concern

    included do
      try :allow_unauthenticated_access

      before_action do
        @template = "baseline/errors/show"
      end

      rescue_from ActionView::MissingTemplate do
        render @template
      end

      helper_method :cta_path
    end

    def show
      @id = params[:id]
        .presence_in(%w[400 403 404 406 422 500]) ||
          "404"

      set_noindex_header
      expires_now

      render "#{::Current.namespace}/errors/show",
        status:  @id.to_i,
        formats: :html
    end

    private

      def page_title        = "Error #{@id}"
      def action_i18n_scope = super(@id)
      def cta_path          = [::Current.namespace, :root]
  end
end
