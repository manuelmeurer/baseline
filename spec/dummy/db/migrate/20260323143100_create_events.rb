# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :started_at, null: false
      t.integer :duration, null: false
      t.virtual :ended_at, type: :datetime, as: "datetime(started_at, '+' || duration || ' minutes')", stored: true
      t.timestamps
    end
  end
end
