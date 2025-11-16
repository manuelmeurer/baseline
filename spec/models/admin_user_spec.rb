# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminUser do
  describe ".schema_columns" do
    it "returns the correct hash of column metadata" do
      expect(AdminUser.schema_columns).to eq(
        alternate_emails: { type: :json, default: [], null: false },
        created_at:       { type: :datetime, null: false },
        position:         { type: :string },
        tokens:           { type: :json, default: {}, null: false },
        updated_at:       { type: :datetime, null: false },
        user_id:          { type: :integer, null: false }
      )
    end
  end
end
