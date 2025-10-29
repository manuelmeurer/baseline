# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Baseline::ApplicationControllerCore,
          Baseline::NamespaceLayout,
          Baseline::PageTitle

  before_action prepend: true do
    Current.modal_request = specific_turbo_frame_request?(:modal)
    Current.namespace     = controller_path.split("/").first.to_sym
    Current.action_name   = action_name
  end

  stale_when_importmap_changes
end
