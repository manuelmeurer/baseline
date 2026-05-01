# frozen_string_literal: true

class AddUsersSearchIndex < ActiveRecord::Migration[8.0]
  include Baseline::Migration::FTS5

  def up
    create_fts5_index :users
  end

  def down
    drop_fts5_index :users
  end
end
