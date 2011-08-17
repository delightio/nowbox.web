class RemoveNonNullConstraintFromAccountUid < ActiveRecord::Migration
  def self.up
    change_column :accounts, :uid, :string, :null => true
  end

  def self.down
    change_column :accounts, :uid, :string, :null => false
  end
end
