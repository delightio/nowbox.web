class AddUidAndProviderToMentionWithIndex < ActiveRecord::Migration
  def self.up
    add_column :mentions, :uid, :string
    add_column :mentions, :source, :string
    i = 0; while i < Aji::Mention.count do
      Aji::Mention.order(:id).limit(500).offset(i).each do |m|
        begin
          m.uid = MultiJson.decode(m.unparsed_data)['id'].to_s
          m.source = 'twitter'
          m.save

        rescue MultiJson::DecodeError => e
          warn "Mention[#{m.id}] had invalid data and could not be migrated. " +
            "So it was destroyed."
            m.destroy
        end
      end
      i += 500
    end
    add_index :mentions, [ :uid, :source ]
  end

  def self.down
    remove_column :mentions, :uid
    remove_column :mentions, :source
    remove_index :mentions, [ :uid, :source ]
  end
end
