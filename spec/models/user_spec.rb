# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "gender determination" do
    before do
      # The gender is only assigned automatically if the class has a presence validator for the "gender" field.
      expect(User.new).to validate_presence_of(:gender)
    end

    it "determines genders correctly" do
      male_user = create(:user, :male)
      expect(male_user.gender).to eq("male")

      female_user = create(:user, :female)
      expect(female_user.gender).to eq("female")
    end
  end

  describe ".schema_columns" do
    it "returns the correct hash of column metadata" do
      expect(User.schema_columns).to eq(
        created_at:      { type: :datetime, null: false },
        email:           { type: :string },
        first_name:      { type: :string, null: false },
        gender:          { type: :integer },
        last_name:       { type: :string, null: false },
        locale:          { type: :string, null: false },
        password_digest: { type: :string },
        remember_token:  { type: :string },
        slug:            { type: :string, null: false },
        title:           { type: :string },
        updated_at:      { type: :datetime, null: false }
      )
    end
  end
end
