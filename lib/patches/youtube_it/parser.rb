class YouTubeIt
  module Parser
    class VideoFeedParser < FeedParser #:nodoc:
      def parse_content(content)
        doc = REXML::Document.new(content)
        entry = doc.elements["entry"]
        parse_entry(entry)
      end

      def parse_author entry
        author_element = entry.elements["author"]
        if author_element
          YouTubeIt::Model::Author.new(
            :name => author_element.elements["name"].text,
            :uri => author_element.elements["uri"].text)
        end
      end

    protected
      def parse_entry(entry)
        video_id = entry.elements["id"].text
        published_at  = entry.elements["published"] ? Time.parse(entry.elements["published"].text) : nil
        updated_at    = entry.elements["updated"] ? Time.parse(entry.elements["updated"].text) : nil

        # parse the category and keyword lists
        categories = []
        keywords = []
        entry.elements.each("category") do |category|
          # determine if  it's really a category, or just a keyword
          scheme = category.attributes["scheme"]
          if (scheme =~ /\/categories\.cat$/)
            # it's a category
            categories << YouTubeIt::Model::Category.new(
                            :term => category.attributes["term"],
                            :label => category.attributes["label"])

          elsif (scheme =~ /\/keywords\.cat$/)
            # it's a keyword
            keywords << category.attributes["term"]
          end
        end

        title = entry.elements["title"].text
        html_content = entry.elements["content"] ? entry.elements["content"].text : nil

        author = parse_author entry

        media_group = entry.elements["media:group"]

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        description = ""
        unless media_group.elements["media:description"].nil?
          description = media_group.elements["media:description"].text
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        duration = 0
        unless media_group.elements["yt:duration"].nil?
          duration = media_group.elements["yt:duration"].attributes["seconds"].to_i
        end

        # if content is not available on certain region, there is no media:description, media:player or yt:duration
        player_url = ""
        unless media_group.elements["media:player"].nil?
          player_url = media_group.elements["media:player"].attributes["url"]
        end

        unless media_group.elements["yt:aspectRatio"].nil?
          widescreen = media_group.elements["yt:aspectRatio"].text == 'widescreen' ? true : false
        end

        media_content = []
        media_group.elements.each("media:content") do |mce|
          media_content << parse_media_content(mce)
        end

        # parse thumbnails
        thumbnails = []
        media_group.elements.each("media:thumbnail") do |thumb_element|
          # TODO: convert time HH:MM:ss string to seconds?
          thumbnails << YouTubeIt::Model::Thumbnail.new(
                          :url    => thumb_element.attributes["url"],
                          :height => thumb_element.attributes["height"].to_i,
                          :width  => thumb_element.attributes["width"].to_i,
                          :time   => thumb_element.attributes["time"])
        end

        rating_element = entry.elements["gd:rating"]
        extended_rating_element = entry.elements["yt:rating"]

        rating = nil
        if rating_element
          rating_values = {
            :min         => rating_element.attributes["min"].to_i,
            :max         => rating_element.attributes["max"].to_i,
            :rater_count => rating_element.attributes["numRaters"].to_i,
            :average     => rating_element.attributes["average"].to_f
          }

          if extended_rating_element
            rating_values[:likes] = extended_rating_element.attributes["numLikes"].to_i
            rating_values[:dislikes] = extended_rating_element.attributes["numDislikes"].to_i
          end

          rating = YouTubeIt::Model::Rating.new(rating_values)
        end

        if (el = entry.elements["yt:statistics"])
          view_count, favorite_count = el.attributes["viewCount"].to_i, el.attributes["favoriteCount"].to_i
        else
          view_count, favorite_count = 0,0
        end

        noembed = entry.elements["yt:noembed"] ? true : false
        racy = entry.elements["media:rating"] ? true : false

        if where = entry.elements["georss:where"]
          position = where.elements["gml:Point"].elements["gml:pos"].text
          latitude, longitude = position.split(" ")
        end

        control = entry.elements["app:control"]
        state = { :name => "published" }
        if control && control.elements["yt:state"]
          state = {
            :name        => control.elements["yt:state"].attributes["name"],
            :reason_code => control.elements["yt:state"].attributes["reasonCode"],
            :help_url    => control.elements["yt:state"].attributes["helpUrl"],
            :copy        => control.elements["yt:state"].text
          }

        end

        YouTubeIt::Model::Video.new(
          :video_id       => video_id,
          :published_at   => published_at,
          :updated_at     => updated_at,
          :categories     => categories,
          :keywords       => keywords,
          :title          => title,
          :html_content   => html_content,
          :author         => author,
          :description    => description,
          :duration       => duration,
          :media_content  => media_content,
          :player_url     => player_url,
          :thumbnails     => thumbnails,
          :rating         => rating,
          :view_count     => view_count,
          :favorite_count => favorite_count,
          :widescreen     => widescreen,
          :noembed        => noembed,
          :racy           => racy,
          :where          => where,
          :position       => position,
          :latitude       => latitude,
          :longitude      => longitude,
          :state          => state)
      end
    end

    class PlaylistVideosFeedParser < VideoFeedParser
    private
      def parse_author entry
        uploader_credit = entry.elements['media:group'].elements['media:credit']
        if uploader_credit
          YouTubeIt::Model::Author.new name: uploader_credit.text,
            uri: "http://gdata.youtube.com/feeds/api/users/#{uploader_credit.text}"
        end
      end

      def parse_content(content)
        videos  = []
        doc     = REXML::Document.new(content)
        feed    = doc.elements["feed"]
        if feed
          feed_id            = feed.elements["id"].text
          updated_at         = Time.parse(feed.elements["updated"].text)
          total_result_count = feed.elements["openSearch:totalResults"].text.to_i
          offset             = feed.elements["openSearch:startIndex"].text.to_i
          max_result_count   = feed.elements["openSearch:itemsPerPage"].text.to_i

          feed.elements.each("entry") do |entry|
            videos << parse_entry(entry)
          end
        end
        YouTubeIt::Response::VideoSearch.new(
          :feed_id            => feed_id || nil,
          :updated_at         => updated_at || nil,
          :total_result_count => total_result_count || nil,
          :offset             => offset || nil,
          :max_result_count   => max_result_count || nil,
          :videos             => videos)
      end
    end
  end
end

