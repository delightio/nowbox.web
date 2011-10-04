class AddRegionTable < ActiveRecord::Migration
  def self.up
    create_table :regions do |t|
      t.string :locale
      t.string :time_zone

      t.timestamps
    end

  end

  def self.down
    drop_table :regions
  end
end
