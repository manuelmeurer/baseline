# frozen_string_literal: true

Rails.application.routes.draw do
  extend Baseline::Routes

  direct :web_root do
    %i[web home]
  end

  constraints URLManager.route_constraints(:web) do
    namespace :web, path: "" do
      concerns :errors, :essentials, :health

      Web::PagesController::PAGES.each do |id|
        if id == "home"
          root "pages#show", id:, as: id
        else
          get id => "pages#show", id:, as: id
        end
      end
    end
  end

  constraints URLManager.route_constraints(:admin) do
    mount MissionControl::Jobs::Engine => "bgjobs"

    namespace :admin, path: "" do
      concerns :auth, :errors, :essentials, :health, :oauth
      root "dashboards#show"
    end
  end
end
