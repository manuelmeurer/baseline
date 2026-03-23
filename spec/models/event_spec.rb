# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event do
  describe ".schema_columns" do
    it "returns the correct hash of column metadata including virtual columns" do
      expect(Event.schema_columns).to eq(
        created_at:  { type: :datetime, null: false },
        description: { type: :text },
        duration:    { type: :integer, null: false },
        ended_at: {
          type:    :datetime,
          virtual: { as: "datetime(started_at, '+' || duration || ' minutes')", stored: true }
        },
        started_at:  { type: :datetime, null: false },
        title:       { type: :string, null: false },
        updated_at:  { type: :datetime, null: false }
      )
    end
  end
end
