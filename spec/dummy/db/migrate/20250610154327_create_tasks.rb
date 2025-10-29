# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.string :todoist_id, index: { unique: true }
      t.string :identifier
      t.text :details
      t.datetime :done_at
      t.date :due_on, null: false
      t.integer :priority, null: false
      t.references :responsible, polymorphic: true, null: false
      t.references :creator, polymorphic: true
      t.references :taskable, polymorphic: true
      t.timestamps
    end
  end
end
