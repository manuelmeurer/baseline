# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin dashboards", type: :request do
  let(:admin_user) { create(:admin_user) }

  describe "GET /cms" do
    it "redirects unauthenticated users to the admin login" do
      get "/cms"

      expect(response).to redirect_to("http://admin.localtest.me/login")
    end

    it "renders the CMS dashboard for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/cms"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("CMS")
    end
  end

  describe "GET /design" do
    it "redirects unauthenticated users to the admin login" do
      get "/design"

      expect(response).to redirect_to("http://admin.localtest.me/login")
    end

    it "renders the Design dashboard for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/design"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Design")
    end
  end
end
