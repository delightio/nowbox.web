module Aji
  class Channel::FacebookStream < Channel
   has_one :owner, :class_name => 'Aji::Account',
     :foreign_key => :stream_channel_id

    def refresh_content force=false
      super force do |new_videos|
        mentions = owner.api.video_mentions_in_feed
        mentions.each do |mention|
          mention.videos.each do |video|
            video.populate unless video.populated?

            if video.populated?
              new_videos << video
              push video, mention.published_at
            end
          end
        end
      end
    end
  end
end
