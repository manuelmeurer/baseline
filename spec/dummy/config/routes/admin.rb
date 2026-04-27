# frozen_string_literal: true

constraints URLManager.route_constraints(:admin) do
  namespace :admin, path: "" do
    mount Baseline::Admin::Engine, at: ""
  end
end
