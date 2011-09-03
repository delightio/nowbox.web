module Aji
  class Mention::Processor
    attr_accessor :mention, :destination

    def initialize mention, destination
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
            @mention.videos << video
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

        if @mention.spam?
          Resque.enqueue Queues::RemoveSpammer, @mention.author.id
          @errors << "Mention is spammy"
          return
        end

      rescue ActiveRecord::StatementInvalid => e
        raise unless e.message =~ /invalid byte sequence for encoding "UTF8"/
          @errors << "Invalid Characters in #{@mention.body}"
      end

      unless failed?
        @mention.videos.each { |v| @destination.push_recent v }
      end
    end

    def errors
      @errors.join ', '
    end

    def failed?
      not @errors.empty?
    end

    # A hash of functions to extract links (if any) from the tweet and
    # determine if they contain videos. Returns true if it does, otherwise false
    def self.video_filters
      {
        'twitter' => ->(tweet_hash) do
          return false if tweet_hash['entities']['urls'].empty?
          tweet_hash['entities']['urls'].any? do |url|
            Link.new(url['expanded_url'] || url['url']).video?
          end
        end
      }
    end
  end
end

