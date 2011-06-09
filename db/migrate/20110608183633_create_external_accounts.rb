class CreateExternalAccounts < ActiveRecord::Migration
  def self.up
    create_table :external_accounts do |t|
      t.text :user_info
      t.string :provider, :null => false
      t.string :uid, :null => false
      t.string :type
    end
  end

  def self.down
    drop_table :external_accounts
  end
end
