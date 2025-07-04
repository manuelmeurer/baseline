# frozen_string_literal: true

module Baseline
  class ModalComponent < ApplicationComponent
    def before_render
      @stimco = helpers.stimco(:modal,
        default_size: modal_default_size,
        loading:      render(LoadingComponent.new),
        to_h:         false
      )
    end
  end
end
