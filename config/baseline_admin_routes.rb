# frozen_string_literal: true

Baseline::Admin::Engine.routes.draw do
  extend Baseline::Routes

  concerns :auth, :errors, :essentials, :health, :oauth

  root to: "dashboards#show", as: :admin_root

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

  scope path: "jobs", module: :jobs do
    resources :queues, only: %i[index show] do
      scope module: :queues do
        resource :pause, only: %i[create destroy]
      end
    end

    resources :workers, only: %i[index show]
    resources :recurring_tasks, only: %i[index show update]

    resources :jobs, only: :show, path: "" do
      resource :retry, only: :create
      resource :discard, only: :create
      resource :dispatch, only: :create

      collection do
        resource :bulk_retries, only: :create
        resource :bulk_discards, only: :create
      end
    end

    resources :jobs,
      only: :index,
      path: ":status/jobs"

    root to: "queues#index", as: :jobs_dashboard
  end
end
