module Aji
  class Mention::Processor
    attr_accessor :mention, :destination

    def initialize mention, destination
      @mention = mention
      @destination = destination
      @errors = Array.new
    end

    def perform

      if @mention.author.blacklisted?
        @errors << "Author #{@mention.author} is blacklisted."
        return
      end

      if @mention.spam?
        @mention.author.blacklist
        @errors << "Mention: #{@mention.body} is Spammy"
        return
      end

      @mention.links.map(&:to_video).compact.each do |video|
        if video.blacklisted?
          @errors << "Video[#{video.id} is blacklisted"
        else
          @mention.videos << video
        end
      end

      unless @mention.author.save
        @errors << "Unable to save #{@mention.author} due to " +
          @mention.author.errors.inspect
      end

      unless @mention.save
        begin
          @errors << "Unable to save #{@mention} due to " +
            @mention.errors.inspect
        rescue PGError => e
          raise unless e.message =~ /invalid byte sequence for encoding "UTF8"/
            @errors << "Invalid Characters in #{@mention.body}"
        end
      end

      return nil if !@errors.empty?

      @mention.videos.each { |v| @destination.push_recent v } if @errors.empty?
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
        'twitter' => lambda do |tweet_hash|
          return false if tweet_hash['entities']['urls'].empty?

          tweet_hash['entities']['urls'].map do |url|
            Link.new(url['expanded_url'] || url['url']).video?
          end.inject do |acc, bool| acc ||= bool end
        end
      }
    end
  end
end

