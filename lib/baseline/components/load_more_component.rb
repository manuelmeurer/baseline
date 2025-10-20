# frozen_string_literal: true

module Baseline
  class LoadMoreComponent < ApplicationComponent
    def initialize(pagy:)
      @pagy = pagy
    end

    def call
      @pagy.vars[:request_path] = url_for(format: :turbo_stream)

      url =
        @pagy.is_a?(Pagy::Keyset) ?
          pagy_keyset_next_url(@pagy) :
          pagy_next_url(@pagy)

      return unless url

      helpers.turbo_frame_tag :load_more, src: url, loading: :lazy do
        tag.div class: "mt-5 text-center" do
          component :loading
        end
      end
    end
  end
end
