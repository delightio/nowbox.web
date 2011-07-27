class AddUsernameToAccount < ActiveRecord::Migration
  def self.up
    add_column :external_accounts, :username, :string
    Aji::ExternalAccounts::Youtube.all.each do |a|
      a.username = a.uid
      a.save
    end
  end

  def self.down
    remove_column :external_accounts, :username
  end
end
