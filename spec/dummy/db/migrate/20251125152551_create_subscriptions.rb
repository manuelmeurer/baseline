# frozen_string_literal: true

class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :identifier, null: false, index: { unique: true }
      t.timestamps
    end

    create_table :user_subscriptions do |t|
      t.references :user, foreign_key: true, null: false
      t.references :subscription, foreign_key: true, null: false
      t.timestamps
    end
  end
end
