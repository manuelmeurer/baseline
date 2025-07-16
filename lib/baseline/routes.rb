# frozen_string_literal: true

module Baseline
  module Routes
    def self.extended(routes)
      routes.concern :errors do
        match ":id",
          to:  "errors#show",
          via: :all,
          id:  /\d{3}/
      end

      routes.concern :health do
        get "up" => "/rails/health#show", as: :rails_health_check
      end

      routes.concern :sitemap do
        get :sitemap,
          controller: "base",
          defaults:   { format: "xml" },
          format:     true
      end

      routes.concern :pwa do
        get :manifest,
          controller: "base"
      end

      routes.concern :auth do
        scope controller: :sessions do
          get    :login,  action: "new"
          post   :login,  action: "create"
          delete :logout, action: "destroy"
        end
      end

      %i[allow disallow].each do |action|
        routes.concern :"#{action}_robots" do
          get :robots,
            controller: "base",
            id:         action,
            defaults:   { format: "text" },
            format:     true
        end
      end
    end
  end
end
