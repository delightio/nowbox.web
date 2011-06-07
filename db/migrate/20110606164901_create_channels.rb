class CreateChannels< ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      t.string :title
      t.string :videos_key
      t.string :contributors_key
      t.string :channel_type

      t.timestamps
    end
  end

  def self.down
    drop_table :channels
  end
end
