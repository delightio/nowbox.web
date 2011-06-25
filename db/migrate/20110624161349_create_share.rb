class CreateShare < ActiveRecord::Migration
  def self.up
    create_table :shares do |t|
      t.text :message
      t.integer :user_id
      t.integer :video_id

      t.timestamps
    end
  end

  def self.down
    remove_table :shares
  end
end
