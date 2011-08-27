class AddTimestampsToAccount < ActiveRecord::Migration
  def self.up
    change_table :accounts do |t|
      t.timestamps
    end
  end

  def self.down

  end
end
