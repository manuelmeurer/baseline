# frozen_string_literal: true

class CreateAdminUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_users do |t|
      t.json :tokens, default: {}, null: false
      t.json :alternate_emails, default: [], null: false
      t.check_constraint "JSON_TYPE(alternate_emails) = 'array'", name: "user_alternate_emails_is_array"
      t.references :user, foreign_key: true, null: false
      t.timestamps
    end
  end
end
