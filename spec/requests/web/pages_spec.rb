# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Web pages" do
  it "serves the web home path successfully" do
    get web_home_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Baseline Dummy Home")
  end

  it "serves the health check endpoint" do
    get web_rails_health_check_path
    expect(response).to have_http_status(:ok)
  end
end
