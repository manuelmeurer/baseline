# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin authentication with login token" do
  let(:admin_user) { create(:admin_user) }
  let(:login_token) { admin_user.login_token }

  describe "GET / (dashboard)" do
    context "when not authenticated" do
      it "redirects to login page" do
        get admin_root_path
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context "when authenticated with login token" do
      it "authenticates the admin user and redirects to the same URL without the token parameter" do
        get admin_root_path, params: { t: login_token }

        expect(response).to redirect_to(admin_root_path)
        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(controller.send(:authenticated?)).to be true
        expect(Current.user).to eq(admin_user.user)
      end
    end

    context "when using an invalid login token" do
      it "redirects to login page" do
        get admin_root_path, params: { t: "invalid_token" }
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context "when using an expired login token" do
      it "redirects to login page" do
        expired_token = login_token

        travel 2.days do
          get admin_root_path, params: { t: expired_token }
          expect(response).to redirect_to(admin_login_path)
        end
      end
    end
  end
end
