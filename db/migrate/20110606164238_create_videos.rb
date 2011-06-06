class CreateVideos< ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.string :external_id
      t.string :source
      t.string :title
      t.string :description
      t.boolean :viewable_mobile

      t.timestamps
    end
  end

  def self.down
    drop_table :videos
  end
end
