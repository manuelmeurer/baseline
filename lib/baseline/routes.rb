# frozen_string_literal: true

module Baseline
  module Routes
    def self.extended(routes)
      routes.concern :essentials do
        controller :essentials do
          get :sitemap,
            defaults: { format: "xml" },
            format:   true

          get :manifest

          get :robots,
            defaults: { format: "text" },
            format:   true

          get :favicon,
            defaults: { format: "ico" },
            format:   true
        end
      end

      routes.concern :errors do
        match ":id",
          to:  "errors#show",
          via: :all,
          id:  /\d{3}/
      end

      routes.concern :oauth do
        namespace :oauth do
          get :authorize
          get :callback
        end
      end

      routes.concern :health do
        get "up" => "/rails/health#show", as: :rails_health_check
      end

      routes.concern :auth do
        controller :sessions do
          get    :login,  action: "new"
          post   :login,  action: "create"
          delete :logout, action: "destroy"
        end
      end

      routes.concern :password_reset do
        resources :passwords,
          param: :token,
          only:  %i[new create edit update]
      end
    end
  end
end
