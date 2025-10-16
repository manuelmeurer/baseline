# frozen_string_literal: true

module Baseline
  class LoadMoreComponent < ApplicationComponent
    def initialize(scope:)
      @scope = scope
    end

    def call
      return if @scope.none? || @scope.last_page?

      helpers.turbo_frame_tag :load_more,
        src:     params.permit!.merge(page: @scope.next_page, format: :turbo_stream),
        loading: :lazy do

        tag.div class: "mt-5 text-center" do
          component :loading
        end
      end
    end
  end
end
