# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminUser do
  describe ".schema_columns" do
    it "returns the correct hash of column metadata" do
      expect(AdminUser.schema_columns).to eq(
        created_at: { type: :datetime, null: false },
        tokens:     { type: :json, default: {}, null: false },
        updated_at: { type: :datetime, null: false },
        user_id:    { type: :integer, null: false }
      )
    end
  end

  describe ".searchable_params" do
    it "includes associated user columns" do
      params = AdminUser.searchable_params

      expect(params).to have_key(:associated_columns)
      expect(params[:associated_columns]).to have_key(:user)
      expect(params[:associated_columns][:user]).to eq(User.searchable_params.fetch(:columns))
    end
  end

  describe ".search" do
    it "delegates to the associated User's FTS5 search" do
      sql = AdminUser.search("test").to_sql

      expect(sql).to match(/users_fts.+MATCH/i)
    end

    it "returns records matching user attributes" do
      admin = create(:admin_user, user: create(:user, first_name: "Findme"))
      create(:admin_user, user: create(:user, first_name: "Other"))

      expect(AdminUser.search("Findme")).to eq([admin])
    end

    it "returns all records for blank query" do
      create_list(:admin_user, 2)

      expect(AdminUser.search("")).to eq(AdminUser.all.to_a)
      expect(AdminUser.search(nil)).to eq(AdminUser.all.to_a)
    end
  end
end
