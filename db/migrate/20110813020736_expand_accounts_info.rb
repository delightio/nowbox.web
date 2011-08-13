class ExpandAccountsInfo < ActiveRecord::Migration
  def self.up
    change_table :accounts do |t|
      t.text :auth_info
      t.string :provider
      t.rename :user_info, :info
    end
  end

  def self.down
    change_table :accounts do |t|
      t.remove :auth_info
      t.remove :provider
      t.rename :info, :user_info
    end
  end
end
