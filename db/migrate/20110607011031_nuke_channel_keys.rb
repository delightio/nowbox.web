class NukeChannelKeys< ActiveRecord::Migration
  # We don't actually need these thanks to Redis::Objects
  def self.up
    change_table :channels do |t|
      t.remove :contributors_key
      t.remove :videos_key
    end
  end

  def self.down
    change_table :channels do |t|
      t.string :contributors_key
      t.string :videos_key
    end
  end
end
