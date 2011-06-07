class CreateAuthorsChannelAuthors < ActiveRecord::Migration
  def self.up
    create_table :authors_authors_channels, :id => false do |t|
      t.integer :authors_channel_id
      t.integer :author_id
    end
  end

  def self.down
    drop_table :authors_authors_channels
  end
end
