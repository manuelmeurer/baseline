# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "gender determination" do
    before do
      # The gender is only assigned automatically if the class has a presence validator for the "gender" field.
      expect(User.new).to validate_presence_of(:gender)
    end

    it "determines genders correctly" do
      male_user = User.create!(
        first_name: "Peter",
        last_name: "Müller",
        email: "peter.mueller@example.com"
      )

      expect(male_user.gender).to eq("male")

      female_user = User.create!(
        first_name: "Petra",
        last_name: "Müller",
        email: "petra.mueller@example.com"
      )

      expect(female_user.gender).to eq("female")
    end
  end
end
