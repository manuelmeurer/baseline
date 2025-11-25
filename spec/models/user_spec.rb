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

  describe ".subscribed" do
    let!(:newsletter) { Subscription.newsletter }
    let!(:secret_newsletter) { Subscription.secret_newsletter }

    let!(:subscribed_user) { create(:user) }
    let!(:unsubscribed_user) { create(:user) }

    before do
      subscribed_user.subscriptions << newsletter
    end

    it "returns users subscribed to the specified identifier" do
      expect(User.subscribed(:newsletter)).to include(subscribed_user)
      expect(User.subscribed(:newsletter)).not_to include(unsubscribed_user)
    end

    it "raises an error for invalid identifiers" do
      expect {
        User.subscribed(:invalid_subscription)
      }.to raise_error(/Identifier is not valid: invalid_subscription/)
    end

    describe "with before: parameter" do
      let!(:old_subscription_time) { 2.days.ago }
      let!(:recent_subscription_time) { 1.hour.ago }

      let!(:old_subscriber) { create(:user) }
      let!(:recent_subscriber) { create(:user) }

      before do
        old_user_subscription = UserSubscription.create!(
          user: old_subscriber,
          subscription: newsletter
        )
        old_user_subscription.update_column(:created_at, old_subscription_time)

        recent_user_subscription = UserSubscription.create!(
          user: recent_subscriber,
          subscription: newsletter
        )
        recent_user_subscription.update_column(:created_at, recent_subscription_time)
      end

      it "filters users who subscribed before the specified time" do
        cutoff_time = 1.day.ago

        subscribed_before_cutoff = User.subscribed(:newsletter, before: cutoff_time)

        expect(subscribed_before_cutoff).to include(old_subscriber)
        expect(subscribed_before_cutoff).not_to include(recent_subscriber)
      end

      it "includes all subscribers when before: is not specified" do
        all_subscribers = User.subscribed(:newsletter)

        expect(all_subscribers).to include(old_subscriber, recent_subscriber)
      end

      it "returns no users when before: time is earlier than all subscriptions" do
        very_early_time = 1.week.ago

        subscribed_before_cutoff = User.subscribed(:newsletter, before: very_early_time)

        expect(subscribed_before_cutoff).to be_empty
      end

      it "returns all subscribers when before: time is later than all subscriptions" do
        future_time = 1.day.from_now

        subscribed_before_cutoff = User.subscribed(:newsletter, before: future_time)

        expect(subscribed_before_cutoff).to include(old_subscriber, recent_subscriber)
      end
    end
  end
end
