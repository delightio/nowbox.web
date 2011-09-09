class AddReasonToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :reason, :string
  end

  def self.down
    remove_column :events, :reason
  end
end
