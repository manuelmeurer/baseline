# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Web essentials" do
  describe "GET /offline" do
    it "renders the offline page without a layout" do
      get web_offline_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You are offline")
      expect(response.body).to include("Try again")
      expect(response.body).not_to include("Baseline Dummy Home")
    end
  end

  describe "GET /offline when render_offline? is false" do
    it "returns 404" do
      allow_any_instance_of(Web::EssentialsController)
        .to receive(:render_offline?)
        .and_return(false)

      get web_offline_path

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /service-worker.js" do
    it "renders the service worker JavaScript" do
      get web_service_worker_path(format: :js)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.headers["Cache-Control"]).to include("no-cache")
      expect(response.body).to include("addEventListener")
      expect(response.body).to include("caches.open")
      expect(response.body).to include(Rails.configuration.revision)
    end

    it "redirects to the .js format when a different format is requested" do
      get "/service-worker.json"

      expect(response).to redirect_to("/service-worker.js")
    end
  end

  describe "GET /service-worker.js when render_service_worker? is false" do
    it "returns 404" do
      allow_any_instance_of(Web::EssentialsController)
        .to receive(:render_service_worker?)
        .and_return(false)

      get web_service_worker_path(format: :js)

      expect(response).to have_http_status(:not_found)
    end
  end
end
