class CreateIdentiesAndAddToExternalAccounts < ActiveRecord::Migration
  def self.up
    create_table :identities do |t|
      t.timestamps
    end

    add_column :external_accounts, :identity_id, :integer
    add_column :users, :identity_id, :integer
  end

  def self.down
    drop_table :identities
    add_column :external_accounts, :identity_id
    add_column :users, :identity_id
  end
end
