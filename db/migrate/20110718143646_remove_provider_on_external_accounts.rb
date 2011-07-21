class RemoveProviderOnExternalAccounts < ActiveRecord::Migration
  def self.up
    remove_column :external_accounts, :provider
  end

  def self.down
    add_column :external_accounts, :provider, :string, :null => false
    Aji::ExternalAccount.all.each{|ea| ea.provider = ea.type.split('::').last.downcase; ea.save}
  end
end
