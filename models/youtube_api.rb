module Aji
  class YoutubeAPI
    USER_FEED_URL = "http://gdata.youtube.com/feeds/api/users"

    attr_reader :uid

    def initialize uid=nil, token=nil, secret=nil
      raise ArgumentError, "Invalid credentials" unless
        (token and secret) or not (token or secret)
      @uid, @token, @secret = uid, token, secret
    end

    def subscriptions uid=uid, uid_subscription_id_hash={}
      tracker.hit!
      client.subscriptions(uid).map do |sub|
        # TODO: We should follow the unique subscription id.
        uid = sub.title.split(" ").last.downcase
        uid_subscription_id_hash.merge! "#{uid}" => sub.id

        account = Account::Youtube.find_or_create_by_lower_uid uid
        account.to_channel
      end
    end

    def subscribe_to channel
      begin
        tracker.hit!
        channel_uid = uid_from_channel channel
        client.subscribe_channel channel_uid
      rescue => e
        Aji.log "YoutubeAPI#subscribe(#{channel_uid}) => #{e}"
      end
    end

    def unsubscribe_from channel
      channel_uid = uid_from_channel channel
      uid_subscription_id_hash = {} # mapping of uid and subscription id
      subscriptions uid, uid_subscription_id_hash

      begin
        client.unsubscribe_channel uid_subscription_id_hash[channel_uid]
      rescue => e
          Aji.log "YoutubeAPI#unsubscribe(#{channel_uid}) => #{e}"
      end
    end

    def favorite_videos uid=uid
      tracker.hit!
      client.favorites(uid).videos.map do |h|
        youtube_it_to_video h
      end
    end

    def favorite_video video
      tracker.hit!
      client.add_favorite video.external_id
    end

    def unfavorite_video video
      tracker.hit!
      client.delete_favorite video.external_id
    end

    def watch_later_videos
      Aji.log :ERROR, "YoutubeAPI#watch_later_videos not implemented yet."
      # tracker.hit!
      # client.playlist('watch_later').videos.map do |h|
      #   youtube_it_to_video h
      # end
    end

    def author_info uid=uid
      tracker.hit!
      DataGrabber.new(uid).build_hash
    end

    def valid_uid? uid=uid
      tracker.hit!
      Faraday.get("#{USER_FEED_URL}/#{uid}").status == 200
    end

    def video_info youtube_id
      tracker.hit!
      youtube_it_to_hash client.video_by youtube_id
    rescue OpenURI::HTTPError => exp
      raise VideoAPI::Error, "Unable to populate #{youtube_id}.", exp.backtrace
    rescue NoMethodError => exp
      raise VideoAPI::Error, "Unable to reach YoutubeAPI.", exp.backtrace
    end

    def video youtube_id
      youtube_it_to_video client.video_by youtube_id
    end

    def uploaded_videos uid=uid
      tracker.hit!
      client.videos_by(:author => uid, :order_by => 'published',
       :per_page => 50).videos.map{ |v| youtube_it_to_video v }
    end

    def keyword_search keywords, per_page=50
      tracker.hit!
      client.videos_by(
        :query => Array(keywords).join(' '),
        :per_page => per_page).
          videos.map{ |v| youtube_it_to_video v }
    end

    def youtube_it_to_hash video
      if youtube_category = video.categories.first
        category = Category.find_or_create_by_raw_title youtube_category.label,
          :title => youtube_category.term
      else
        category = Category.undefined
      end

      author = Account::Youtube.find_or_create_by_lower_uid video.author.name

      {
        :title => video.title,
        :external_id => Link.new(video.player_url).external_id,
        :description => video.description,
        :duration => video.duration,
        :viewable_mobile => (not video.noembed),
        :view_count => video.view_count,
        :category => category,
        :author => author,
        :published_at => video.published_at,
        :source => :youtube,
        :populated_at => Time.now
      }
    end

    def youtube_it_to_video video
      h = youtube_it_to_hash video
      # We indexed by external_id followed by source
      Video.update_or_create_by_external_id_and_source(
        h[:external_id], h[:source], h)
    end

    def tracker
      @@tracker ||= APITracker.new self.class.to_s, Aji.redis,
        cooldown: 1.hour, hits_per_session: 250
    end

    def uid_from_channel channel
      channel.accounts.first.uid
    end

    def client
      @client ||=
        if @token and @secret
          YouTubeIt::OAuthClient.new(consumer_key: Aji.conf['YOUTUBE_OA_KEY'],
            consumer_secret: Aji.conf['YOUTUBE_OA_SECRET'], username: @uid,
            dev_key: Aji.conf['YOUTUBE_KEY']).tap do |c|
              c.authorize_from_access @token, @secret
            end
        else
          @@client ||= YouTubeIt::Client.new dev_key: Aji.conf['YOUTUBE_KEY']
        end
    end
    private :client

    def self.api
      @singleton ||= new
    end

    class DataGrabber
      def initialize youtube_uid, data=nil
        @youtube_uid = youtube_uid
        @feed_url =
          "http://gdata.youtube.com/feeds/api/users/#{youtube_uid}?alt=json&v=2"
        @data = if data then data['entry'] else get_data_from_youtube end
      end

      def uid
        username.downcase
      end

      def published
        time_string = @data.fetch('published', {}).fetch('$t', nil)
        if time_string then DateTime.parse(time_string).to_time else nil end
      end

      def updated
        time_string = @data.fetch('updated', {}).fetch('$t', nil)
        t = if time_string then DateTime.parse(time_string) else nil end
        #t.to_time # Why the shit does this not work?
        return if t.nil?
        t.instance_eval { Time.utc(year, mon, mday, hour, min, sec).getlocal }
      end

      def category
        @data.fetch('category', [nil,{}])[1].fetch('term', '*** undefined ***')
      end

      def title
        @data.fetch('title', {}).fetch('$t', "")
      end

      def about_me
        @data.fetch('yt$aboutMe',{}).fetch('$t', "")
      end

      def profile
        find_link 'alternate'
      end

      def homepage
        find_link 'related'
      end

      def featured_video_id
        link = find_link 'http://gdata.youtube.com/schemas/2007#featured-video'
        match = link.match(Link::YOUTUBE_ID_REGEXP)
        match && match[1] || nil
      end

      def first_name
        @data.fetch('yt$firstName', {}).fetch('$t', "")
      end

      def last_name
        @data.fetch('yt$lastName', {}).fetch('$t', "")
      end

      def hobbies
        @data.fetch('yt$hobbies', {}).fetch('$t', "")
      end

      def location
        @data.fetch('yt$location', {}).fetch('$t', "")
      end

      def occupation
        @data.fetch('yt$occupation', {}).fetch('$t', "")
      end

      def school
        @data.fetch('yt$school', {}).fetch('$t', "")
      end

      def subscriber_count
        @data.fetch('yt$statistics', {}).fetch('subscriberCount', 0).to_i
      end

      def thumbnail
        @data.fetch("media$thumbnail", {}).fetch('url', "")
      end

      def get_data_from_youtube
        response = Faraday.get(@feed_url)
        return {} unless response.status == 200
        MultiJson.decode(response.body)['entry']
      end

      def username
        @data.fetch('yt$username', {}).fetch('$t', "")
      end

      def total_upload_views
        @data.fetch('yt$statistics', {}).fetch('totalUploadViews', 0).to_i
      end

      def find_link link_type
        link = @data.fetch('link', []).find do |link_hash|
          link_hash['rel'] == link_type
        end

        if link then link['href'] else "" end
      end

      def build_hash
        {
          'uid' => uid,
          'published' => published,
          'updated' => updated,
          'category' => category,
          'title' => title,
          'profile' => profile,
          'homepage' => homepage,
          'featured_video_id' => featured_video_id,
          'about_me' => about_me,
          'first_name' => first_name,
          'last_name' => last_name,
          'hobbies' => hobbies,
          'location' => location,
          'occupation' => occupation,
          'school' => school,
          'subscriber_count' => subscriber_count,
          'thumbnail' => thumbnail,
          'username' => username,
          'total_upload_views' => total_upload_views
        }
      end
    end
  end
end

