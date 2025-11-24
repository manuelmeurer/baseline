# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Baseline::ApplicationControllerCore,
          Baseline::NamespaceLayout,
          Baseline::PageTitle
end
