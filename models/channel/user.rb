module Aji
  class Channel::User < Channel

    def thumbnail_uri # LH 220
      case title
      when "Watch Later"
        "http://#{Aji.conf['TLD']}/images/icons/watch_later.png"
      when "Favorites"
        "http://#{Aji.conf['TLD']}/images/icons/favorites.png"
      when "History"
        "http://#{Aji.conf['TLD']}/images/icons/history.png"
      end
    end


    def refresh_content force=false
      # This is a no-op. All actions on this channel are done via its user.
    end

    def merge! other
      other.content_zset.members(:with_scores => true).each do |(vid,score)|
        content_zset[vid] = score
      end

      other.category_id_zset.members(:with_scores => true).each do |(cid,score)|
        category_id_zset[cid] = score
      end

      other.events.each do |ev|
        events << ev
      end

      save
    end
  end
end
