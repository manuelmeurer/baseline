# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :first_name, :last_name, :password_digest, :locale, :remember_token, null: false
      t.string :email, index: { unique: true }
      t.integer :gender
      t.json :alternate_emails, default: [], null: false
      t.check_constraint "JSON_TYPE(alternate_emails) = 'array'", name: "user_alternate_emails_is_array"
      t.timestamps
    end
  end
end
