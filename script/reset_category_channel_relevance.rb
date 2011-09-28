require_relative '../aji'

module Aji
  Category.all.each do |cat|
    Aji.log "Clearing out Cateogry[#{cat.id}], #{cat.raw_title} (n channels: #{cat.channel_ids.count})..."
    redis.del cat.channel_id_zset.key
  end
  puts

  [Channel::Keyword, Channel::Account].each do |channel_class|
    Aji.log "Updating from #{channel_class.count} #{channel_class} channels..."
    channel_class.find_each do |ch|
      Aji.log "  Channel[#{ch.id}], #{ch.title}, #{ch.content_video_id_count}"
      ch.update_relevance_in_categories ch.content_videos
    end
    puts
  end

  Category.all.each do |cat|
    Aji.log "Cateogry[#{cat.id}], #{cat.raw_title}, has #{cat.channel_ids.count} channels, " +
      "featured: #{cat.featured_channels.count}"
  end
end