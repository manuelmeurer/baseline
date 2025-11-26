# frozen_string_literal: true

class CreateDeactivations < ActiveRecord::Migration[8.0]
  def change
    create_table :deactivations do |t|
      t.string :reason, null: false
      t.text :details
      t.datetime :revoked_at
      t.references :deactivatable, polymorphic: true, null: false
      t.references :initiator, polymorphic: true
      t.timestamps
    end
  end
end
