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

  describe "GET /storage" do
    it "redirects unauthenticated users to the admin login" do
      get "/storage"

      expect(response).to redirect_to("http://admin.localtest.me/login")
    end

    it "renders the Storage dashboard for authenticated users" do
      get "/", params: { t: admin_user.login_token }

      get "/storage"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Storage")
      expect(response.body).to include("Blobs")
      expect(response.body).to include("Attachments")
    end
  end

  describe "GET /storage/blobs" do
    it "lists blobs for authenticated users" do
      blob = create_blob(filename: "report.txt")

      get "/", params: { t: admin_user.login_token }
      get "/storage/blobs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(blob.filename.to_s)
    end
  end

  describe "GET /storage/blobs/:id" do
    it "renders blob details for authenticated users" do
      blob = create_blob(filename: "details.txt")

      get "/", params: { t: admin_user.login_token }
      get "/storage/blobs/#{blob.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(blob.filename.to_s)
      expect(response.body).to include(blob.key)
    end
  end

  describe "GET /storage/attachments" do
    it "lists attachments for authenticated users" do
      attachment = create_attachment

      get "/", params: { t: admin_user.login_token }
      get "/storage/attachments"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(attachment.name)
      expect(response.body).to include(attachment.blob.filename.to_s)
    end
  end

  describe "GET /storage/attachments/:id" do
    it "renders attachment details for authenticated users" do
      attachment = create_attachment

      get "/", params: { t: admin_user.login_token }
      get "/storage/attachments/#{attachment.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(attachment.name)
      expect(response.body).to include(attachment.blob.filename.to_s)
    end
  end

  def create_blob(filename:)
    ActiveStorage::Blob.create_and_upload!(
      io:           StringIO.new("hello"),
      filename:,
      content_type: "text/plain"
    )
  end

  def create_attachment
    ActiveStorage::Attachment.create!(
      name:   "photo",
      record: create(:user, :male),
      blob:   create_blob(filename: "avatar.png")
    )
  end
end
