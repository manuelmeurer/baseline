# frozen_string_literal: true

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
