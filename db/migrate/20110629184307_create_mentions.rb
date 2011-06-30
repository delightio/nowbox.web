class CreateMentions < ActiveRecord::Migration
  def self.up
    create_table :mentions do |t|
      t.integer :author_id
      t.integer :external_id
      t.text :body
      t.text :unparsed_data

      t.timestamps
    end
  end

  def self.down
    remove_table :mentions
  end
end
