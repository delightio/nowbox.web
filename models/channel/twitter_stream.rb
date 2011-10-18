module Aji
  class Channel::TwitterStream < Channel

   has_one :owner, :class_name => 'Aji::Account',
     :foreign_key => :stream_channel_id

    validates_presence_of :owner

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/twitter.png"
    end

    def refresh_content force=false
      super force do |new_videos|
        owner.api.video_mentions_in_feed.each do |m|
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
