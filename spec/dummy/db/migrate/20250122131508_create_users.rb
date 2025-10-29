# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :first_name, :last_name, :password_digest, :locale, :remember_token, null: false
      t.string :email, index: { unique: true }
      t.integer :gender
      t.timestamps
    end
  end
end
