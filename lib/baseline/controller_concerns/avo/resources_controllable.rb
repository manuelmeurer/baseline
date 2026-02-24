# frozen_string_literal: true

module Baseline
  module Avo
    module ResourcesControllable
      extend ActiveSupport::Concern

      included do
        # Avo's default-value hydration reads via_relation_class, but the modal flow sends via_belongs_to_resource_class.
        # Normalize here so "new via belongs_to" preselects the parent consistently across resources.
        before_action do
          params[:via_relation_class] ||= params[:via_belongs_to_resource_class]
        end

        # Convert ?search=foo into encoded_filters for the Search filter.
        before_action only: :index, if: -> { params[:search].present? } do
          search_value = params.delete(:search)
          resource_class = self
            .class
            .name
            .delete_prefix("Avo::")
            .delete_suffix("Controller")
            .singularize
            .then { "Avo::Resources::#{_1}" }
            .constantize

          unless resource_class.model_class.respond_to?(:search)
            ReportError.call "Resource #{resource_class} was called with a search param, but it has no search filter configured."
            redirect_to url_for(params.permit!)
            next
          end

          encoded = ::Avo::Filters::BaseFilter.encode_filters(
            Filters::Search.to_s => search_value
          )
          redirect_to url_for(params.permit!.merge(encoded_filters: encoded))
        end
      end

      # Avo's default view includes TurboFrameWrapperComponent, but it only wraps content in a <turbo-frame> tag — it doesn't add the modal UI.
      # Our custom templates does both:
      # - turbo_frame_tag Avo::MODAL_FRAME_ID — so Turbo can match the response to the frame (same as what TurboFrameWrapperComponent does)
      # - Avo::ModalComponent — provides the fixed overlay, backdrop, and Stimulus modal controller that makes it visually appear as a modal

      def show
        super

        if modal_request?
          render "baseline/avo/modal_show"
        end
      end

      def new
        super

        if modal_request?
          render "baseline/avo/modal_new"
        end
      end

      def create_success_action
        if modal_request?
          render turbo_stream: turbo_stream.replace(::Avo::MODAL_FRAME_ID) {
            helpers.tag.script("Turbo.visit(window.location.href)")
          }
        else
          super
        end
      end

      private

        def modal_request?
          request.headers["Turbo-Frame"] == ::Avo::MODAL_FRAME_ID.to_s
        end
    end
  end
end
