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
end
