# frozen_string_literal: true

class CreateAdminUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_users do |t|
      t.json :tokens, default: {}, null: false
      t.references :user, foreign_key: true, null: false
      t.timestamps
    end
  end
end
