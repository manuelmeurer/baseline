# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FTS5 search" do
  describe "User.search" do
    let!(:alice) { create(:user, first_name: "Alice", last_name: "Anderson", email: "alice@example.com") }
    let!(:bob)   { create(:user, first_name: "Bob",   last_name: "Brown",    email: "bob@example.com")   }

    it "matches by first name" do
      expect(User.search("Alice")).to eq([alice])
    end

    it "matches by last name" do
      expect(User.search("Brown")).to eq([bob])
    end

    it "matches by email local part" do
      expect(User.search("alice")).to eq([alice])
    end

    it "supports prefix matching" do
      expect(User.search("Ali")).to eq([alice])
    end

    it "returns all users for a blank query" do
      expect(User.search("")).to eq(User.all.to_a)
      expect(User.search(nil)).to eq(User.all.to_a)
    end

    it "returns nothing for a non-matching query" do
      expect(User.search("zzznoone")).to be_empty
    end

    it "is case-insensitive" do
      expect(User.search("ALICE")).to eq([alice])
    end
  end

  describe "trigger maintenance" do
    it "indexes new rows on INSERT" do
      user = create(:user, first_name: "Newcomer")
      expect(User.search("Newcomer")).to eq([user])
    end

    it "updates the index on UPDATE" do
      user = create(:user, first_name: "Original")
      user.update!(first_name: "Renamed")

      expect(User.search("Original")).to be_empty
      expect(User.search("Renamed")).to eq([user])
    end

    it "removes from the index on DELETE" do
      user = create(:user, first_name: "Doomed")
      user.delete

      expect(User.search("Doomed")).to be_empty
    end

    it "cascades to AdminUser searches when the user changes" do
      admin = create(:admin_user, user: create(:user, first_name: "Initial"))
      admin.user.update!(first_name: "Updated")

      expect(AdminUser.search("Initial")).to be_empty
      expect(AdminUser.search("Updated")).to eq([admin])
    end
  end

  describe "missing FTS5 table" do
    it "raises a clear error when the model has searchable columns but no FTS5 table" do
      User.instance_variable_set(:@_fts5_table_checked, false)
      allow(User.connection).to receive(:select_value).and_call_original
      allow(User.connection).to receive(:select_value).with(/sqlite_master.*users_fts/).and_return(nil)

      expect { User.search("anything").to_a }
        .to raise_error(/Missing FTS5 virtual table `users_fts`/)
    ensure
      User.instance_variable_set(:@_fts5_table_checked, false)
    end

    it "memoizes the check so it runs only once" do
      User.instance_variable_set(:@_fts5_table_checked, false)
      expect(User.connection).to receive(:select_value).with(/sqlite_master.*users_fts/).once.and_call_original

      3.times { User.search("alice").to_a }
    ensure
      User.instance_variable_set(:@_fts5_table_checked, false)
    end

    it "raises a clear error when the FTS5 table columns drift from searchable_params" do
      User.instance_variable_set(:@_fts5_table_checked, false)
      allow(User).to receive(:searchable_params)
        .and_return(columns: %i[first_name last_name email phone])

      expect { User.search("anything").to_a }
        .to raise_error(/FTS5 column drift on `users_fts`.*recreate_fts5_index :users/m)
    ensure
      User.instance_variable_set(:@_fts5_table_checked, false)
    end
  end

  describe "recreate_fts5_index" do
    it "drops and recreates the FTS5 table, repopulating from source data" do
      user = create(:user, first_name: "Persistent")
      expect(User.search("Persistent")).to eq([user])

      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.new.extend(Baseline::Migration::FTS5)
          .recreate_fts5_index(:users, columns: %i[first_name last_name email])
      end

      User.instance_variable_set(:@_fts5_table_checked, false)
      expect(User.search("Persistent")).to eq([user])
    end
  end
end
