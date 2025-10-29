# frozen_string_literal: true

Rails.application.routes.draw do
  extend Baseline::Routes

  constraints URLManager.route_constraints(:web) do
    namespace :web, path: "" do
      concerns :errors, :essentials, :health

      I18n.with default_locale: :de do
        localized do
          Web::PagesController::PAGES.each do |id|
            if id == "home"
              root "pages#show", id:, as: id
              get "v/:via" => "pages#show", id:, as: "#{id}_via"
            else
              get "#{id}(/v/:via)" => "pages#show", id:, as: id
            end
          end
        end
      end
    end
  end

  constraints URLManager.route_constraints(:admin) do
    namespace :admin, path: "" do
      concerns :auth, :errors, :essentials, :health, :oauth
      root "dashboards#show"
    end
  end
end
