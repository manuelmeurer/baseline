# frozen_string_literal: true

Baseline::Admin::Engine.routes.draw do
  extend Baseline::Routes

  concerns :auth, :errors, :essentials, :health, :oauth

  root to: "dashboards#show"

  scope path: "errors" do
    root to: "/baseline/errors/dashboards#show", as: :errors_dashboard

    resources :issues,
      controller: "/baseline/errors/issues",
      only:       %i[index show] do

      member do
        post :resolve
        post :unresolve
      end
    end
  end
end
