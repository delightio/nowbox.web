class YouTubeIt
  class Client
    def add_watch_later video_id
      client.add_watch_later video_id
    end

    def delete_watch_later playlist_entry_id
      client.delete_watch_later playlist_entry_id
    end

    def watch_later user = nil, opts = {}
      client.watch_later user, opts
    end
  end
end
