# frozen_string_literal: true

class CreateVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :versions, force: true do |t|
      t.string :event, null: false
      t.string :whodunnit
      t.json :object, :object_changes
      t.references :item, polymorphic: true, null: false
      t.datetime :created_at
    end
  end
end
