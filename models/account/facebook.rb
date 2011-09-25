module Aji
  class Account::Facebook < Account
    include Redis::Objects
    include Mixins::CanRefreshContent

    validates_presence_of :uid
    validates_uniqueness_of :uid

    def searchable?; false; end

    def refresh_content force=false
      super force do |new_videos|

      end
    end

    def thumbnail_uri
      info["profile_uri"]
    end

    def profile_uri
      info["profile_uri"]
    end

    def realname
      info["realname"]
    end

    def get_user_info
      fb_hash =
        MultiJson.decode(Faraday.get("http://graph.facebook.com/#{uid}").body)

      info["thumbnail_uri"] = "http://graph.facebook.com/#{uid}/picture"
      info["profile_uri"] = fb_hash["link"]
      info["description"] = ""
      info["realname"] = fb_hash["name"]
    end
  end
end
