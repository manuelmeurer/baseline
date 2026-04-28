# frozen_string_literal: true

Baseline::Admin::Engine.routes.draw do
  extend Baseline::Routes

  concerns :auth, :errors, :essentials, :health, :oauth

  root to: "dashboards#show"

  scope path: "errors" do
    root to: "errors/dashboards#show", as: :errors_dashboard

    resources :issues,
      controller: "errors/issues",
      only:       %i[index show] do

      member do
        post :resolve
        post :unresolve
      end
    end
  end

  scope path: "cms" do
    root to: "cms/dashboards#show", as: :cms_dashboard
  end

  scope path: "design" do
    root to: "design/dashboards#show", as: :design_dashboard
  end
end
