require_relative '../aji'

module Aji
  Category.all.each do |cat|
    Aji.log "Clearing out Cateogry[#{cat.id}], #{cat.raw_title} (n channels: #{cat.channel_ids.count})..."
    redis.del cat.channel_id_zset.key
  end
  puts

  non_yt = []
  incomplete = []
  [Channel::Account].each do |channel_class|
    c=0
    Aji.log "Updating from #{channel_class.count} #{channel_class} channels..."
    channel_class.find_each do |ch|
      print " #{c.to_s.rjust(4)}  Channel[#{ch.id}], #{ch.title},"
      puts " #{ch.content_video_id_count}, #{ch.relevance} (#{ch.subscriber_count})"
      c += 1
      if ch.accounts.any? {|a| a.class != Account::Youtube }
        Aji.log "    ** non youtube acccounts. Skipping..."
        non_yt << ch.id
        next
      end

      all_refreshed = ch.accounts.all? {|a| a.refreshed? }
      if all_refreshed
          ch.update_relevance_in_categories
      else
        Aji.log "    *  Channel[#{ch.id}] does not have all info needed. *" if !all_refreshed
        incomplete << ch.id
      end
    end
    puts
  end

  Category.all.each do |cat|
    Aji.log "Cateogry[#{cat.id}], #{cat.raw_title}, has #{cat.channel_ids.count} channels, " +
      "featured: #{cat.featured_channels.count}, #{cat.featured_channels.map(&:title).join(" | ")}"
  end

  puts "non_yt = #{non_yt}"
  puts "incomplete = #{incomplete}"
end