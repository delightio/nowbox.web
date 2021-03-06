class YouTubeIt
  module Upload
    class VideoUpload
      def add_watch_later video_id
        watch_later_body = video_xml_for :playlist => video_id
        watch_later_url = "/feeds/api/users/default/watch_later"
        response = yt_session.post watch_later_url, watch_later_body

        {:code => response.status, :body => response.body}
      end

      def delete_watch_later playlist_entry_id
        watch_later_headers = { 'GData-Version' => '2' }
        watch_later_url = "/feeds/api/users/default/watch_later/%s" % playlist_entry_id
        response = yt_session.delete watch_later_url, watch_later_headers

        true
      end

      def watch_later user, opts = {}
        watch_later_url = "/feeds/api/users/%s/watch_later#{opts.empty? ? '' : "?#{opts.to_param}"}" % (user ? user : "default")
        response = yt_session.get(watch_later_url)

        YouTubeIt::Parser::PlaylistVideosFeedParser.new(response.body).parse
      end

      def favorites(user, opts = {})
        favorite_url = "/feeds/api/users/%s/favorites#{opts.empty? ? '' : "?#{opts.to_param}"}" % (user ? user : "default")
        response     = yt_session.get(favorite_url)

        return YouTubeIt::Parser::PlaylistVideosFeedParser.new(response.body).parse
      end

      def subscriptions user, opts
        opts['v'] = '2'
        subscription_url = "/feeds/api/users/#{user || 'default'}/subscriptions?#{opts.to_param}"
        response = yt_session.get subscription_url

        YouTubeIt::Parser::SubscriptionFeedParser.new(response).parse
      end
    end
  end
end
