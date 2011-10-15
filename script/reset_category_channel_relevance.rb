require_relative '../aji'

module Aji
  Category.all.each do |cat|
    Aji.log "Clearing out Cateogry[#{cat.id}], #{cat.raw_title} (n channels: #{cat.channel_ids.count})..."
    redis.del cat.channel_id_zset.key
  end
  puts

  [Channel::Account].each do |channel_class|
    Aji.log "Updating from #{channel_class.count} #{channel_class} channels..."
    channel_class.find_each do |ch|
      Aji.log "  Channel[#{ch.id}], #{ch.title}, #{ch.content_video_id_count}, #{ch.relevance} (#{ch.subscriber_count})"

      if ch.accounts.any? {|a| a.class != Account::Youtube }
        Aji.log "  ** non youtube acccounts. Skipping..."
        next
      end

      all_refreshed = ch.accounts.all? {|a| a.refreshed? }
      Aji.log "  * Channel[#{ch.id}] does not have all info needed. *" if !all_refreshed
      ch.update_relevance_in_categories if all_refreshed
    end
    puts
  end

  Category.all.each do |cat|
    Aji.log "Cateogry[#{cat.id}], #{cat.raw_title}, has #{cat.channel_ids.count} channels, " +
      "featured: #{cat.featured_channels.count}, #{cat.featured_channels.map(&:title).join(" | ")}"
  end
end