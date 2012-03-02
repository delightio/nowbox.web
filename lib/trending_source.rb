module Aji
  class TrendingSource
    attr_reader :redis, :video_source

    def initialize config
      @redis_url = config[:redis_url]
      @trending_zset_key = config[:trending_zset_key]
      @max_video_count = config[:max_video_count] || 100
      @video_source = 'youtube'

      connect
    end

    def connect
      uri = URI @redis_url
      redis_config = {:host => uri.host,
                      :port => uri.port,
                      :password => uri.password,
                      :db => uri.path[1..-1]}
      @redis ||= Redis.new redis_config
    end

    def video_uids count=@max_video_count
      @redis.zrevrange @trending_zset_key, 0, (count-1)
    end

    def refresh
      # We are accessing the trending video backwards so that
      # we can simply keep making the current video the top trending
      # within each category
      nowtrending = Channel::Trending.find_or_create_by_title 'NowTrending'
      video_uids.reverse.each do |uid|
        video = Video.find_or_create_by_source_and_external_id @video_source, uid
        video.populate do |v|
          v.category.trending.lpush v
          nowtrending.lpush v
        end
      end
    end
  end
end