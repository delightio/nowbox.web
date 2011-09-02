class AddNameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :name, :string
    Aji::User.all.each do |user|
      name = [user.first_name, user.last_name].join(" ")
      user.update_attribute :name, name
    end
    remove_column :users, :first_name
    remove_column :users, :last_name
  end

  def self.down
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    Aji::User.all.each do |user|
      names = user.name.to_s.split(' ')
      unless names.empty?
        user.update_attribute :first_name, names.first
        user.update_attribute :last_name, names.last
      end
    end
    remove_column :users, :name
  end
end
