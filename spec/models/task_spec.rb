# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task do
  describe ".schema_columns" do
    it "returns the correct hash of column metadata" do
      expect(Task.schema_columns).to eq(
        created_at:       { type: :datetime, null: false },
        creator_id:       { type: :integer },
        creator_type:     { type: :string },
        details:          { type: :text },
        done_at:          { type: :datetime },
        due_on:           { type: :date, null: false },
        identifier:       { type: :string },
        priority:         { type: :integer, null: false },
        responsible_id:   { type: :integer, null: false },
        responsible_type: { type: :string, null: false },
        taskable_id:      { type: :integer },
        taskable_type:    { type: :string },
        title:            { type: :string, null: false },
        todoist_id:       { type: :string },
        updated_at:       { type: :datetime, null: false }
      )
    end
  end
end
