module Aji
  class MentionProcessor
    attr_accessor :mention, :destination

    def initialize mention, destination=nil
      @mention = mention
      @destination = destination
      @errors = Array.new
    end

    def perform
      begin
        @mention.links.map(&:to_video).compact.each do |video|
          if video.blacklisted?
            @errors << "Video[#{video.id}] is blacklisted"
          else
            @mention.videos << video unless @mention.videos.include? video
          end
        end
        return if @mention.videos.empty?

        unless @mention.author.save
          @errors << "Unable to save #{@mention.author.username} due to " +
            @mention.author.errors.inspect
          return
        end

        unless @mention.save
          @errors << "Unable to save #{@mention.inspect} due to " +
            @mention.errors.inspect
        end

        if @destination and @mention.spam?
          Resque.enqueue Queues::RemoveSpammer, @mention.author.id
          @errors << "Mention is spammy"
          return
        end

      rescue ActiveRecord::StatementInvalid => e
        raise unless e.message =~ /invalid byte sequence/
        @errors << "Invalid Characters in #{@mention.body}"
      end

      unless failed?
        @mention.videos.each do |v|
          if @destination.respond_to? :promote_video
            @destination.promote_video v, @mention
          end
        end
      end
    end

    def found_videos
      @mention.videos || []
    end

    def errors
      @errors.join ', '
    end

    def failed?
      not @errors.empty?
    end

    def no_videos?
      @mention.videos.empty?
    end

    # A hash of functions to extract links (if any) from the tweet and
    # determine if they contain videos. Returns true if it does, otherwise false
    def self.video_filters
      {
        'twitter' => lambda do |tweet_hash|
          return false if tweet_hash['entities']['urls'].empty?
          return false if Mention.find_by_uid(tweet_hash['id'].to_s)
          tweet_hash['entities']['urls'].any? do |url|
            Link.new(url['expanded_url'] || url['url']).video?
          end
        end
      }
    end
  end
end

