module Aji
  class Channel::FacebookStream < Channel

    validates_presence_of :owner

   has_one :owner, :class_name => 'Aji::Account',
     :foreign_key => :stream_channel_id

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/nowpopular.png"
    end

    def refresh_content force=false
      super force do |new_videos|
        mentions = owner.api.video_mentions_in_feed
        mentions.each do |m|
          m.videos.each do |v|
            v.populate do |video|
              new_videos << video
              push video, m.published_at
            end
          end
        end
      end
    end
  end
end
