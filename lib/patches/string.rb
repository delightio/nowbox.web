module Aji::RandomString
  def random length = 10
    letters = ('a'..'z').to_a
    (0...length).map { letters[rand 26] }.join
  end
end

module Aji::StringTokenizer
  def tokenize separator=','
    tokens = Set.new self.downcase.split(separator).map(&:strip)
    (tokens - (tokens & @@stopwords)).to_a
  end

  @@stopwords = Set.new %w{ a able about above abst accordance according accordingly across act
                         actually added adj adopted affected affecting affects after afterwards
                         again against ah all almost alone along already also although always
                         am among amongst an and announce another any anybody anyhow anymore
                         anyone anything anyway anyways anywhere apparently approximately are
                         aren arent arise around as aside ask asking at auth available away
                         awfully b back be became because become becomes becoming been before
                         beforehand begin beginning beginnings begins behind being believe
                         below beside besides between beyond biol both brief briefly but by c
                         ca came can cannot cant cause causes certain certainly co com come
                         comes contain containing contains could couldnt d date did didnt
                         different do does doesnt doing done dont down downwards due during e
                         each ed edu effect eg eight eighty either else elsewhere end ending
                         enough especially et et-al etc even ever every everybody everyone
                         everything everywhere ex except f far few ff fifth first five fix
                         followed following follows for former formerly forth found four from
                         further furthermore g gave get gets getting give given gives giving go
                         goes gone got gotten h had happens hardly has hasnt have havent
                         having he hed hence her here hereafter hereby herein heres hereupon
                         hers herself hes hi hid him himself his hither home how howbeit
                         however hundred i id ie if ill im immediate immediately importance
                         important in inc indeed index information instead into invention
                         inward is isnt it itd itll its itself ive j just k keep keeps kept
                         keys kg km know known knows l largely last lately later latter
                         latterly least less lest let lets like liked likely line little ll
                         look looking looks ltd m made mainly make makes many may maybe me mean
                         means meantime meanwhile merely mg might million miss ml more moreover
                         most mostly mr mrs much mug must my myself n na name namely nay nd
                         near nearly necessarily necessary need needs neither never
                         nevertheless new next nine ninety no nobody non none nonetheless noone
                         nor normally nos not noted nothing now nowhere o obtain obtained
                         obviously of off often oh ok okay old omitted on once one ones only
                         onto or ord other others otherwise ought our ours ourselves out
                         outside over overall owing own p page pages part particular
                         particularly past per perhaps placed please plus poorly possible
                         possibly potentially pp predominantly present previously primarily
                         probably promptly proud provides put q que quickly quite qv r ran
                         rather rd re readily really recent recently ref refs regarding
                         regardless regards related relatively research respectively resulted
                         resulting results right run s said same saw say saying says sec
                         section see seeing seem seemed seeming seems seen self selves sent
                         seven several shall she shed shell shes should shouldnt show showed
                         shown showns shows significant significantly similar similarly since
                         six slightly so some somebody somehow someone somethan something
                         sometime sometimes somewhat somewhere soon sorry specifically
                         specified specify specifying state states still stop strongly sub
                         substantially successfully such sufficiently suggest sup sure t take
                         taken taking tell tends th than thank thanks thanx that thatll thats
                         thatve the their theirs them themselves then thence there thereafter
                         thereby thered therefore therein therell thereof therere theres
                         thereto thereupon thereve these they theyd theyll theyre theyve
                         think this those thou though thoughh thousand throug through
                         throughout thru thus til tip to together too took toward towards tried
                         tries truly try trying ts twice two u un under unfortunately unless
                         unlike unlikely until unto up upon ups us use used useful usefully
                         usefulness uses using usually v value various ve very via viz vol
                         vols vs w want wants was wasnt way we wed welcome well went were
                         werent weve what whatever whatll whats when whence whenever where
                         whereafter whereas whereby wherein wheres whereupon wherever whether
                         which while whim whither who whod whoever whole wholl whom whomever
                         whos whose why widely willing wish with within without wont words
                         world would wouldnt www x y yes yet you youd youll your youre yours
                         yourself yourselves youve z zero

                         default_profile show_all_inline_media contributors_enabled
                         geo_enabled notifications profile_sidebar_border_color url
                         lang profile_use_background_image default_profile_image
                         statuses_count profile_background_image_url_https time_zone
                         favourites_count profile_background_color profile_image_url
                         description location following profile_background_image_url
                         id_str follow_request_sent verified friends_count profile_text_color
                         profile_sidebar_fill_color followers_count protected
                         profile_background_tile created_at screen_name name
                         is_translator id listed_count utc_offset profile_link_color
                         profile_image_url_https
                         uid published updated category title profile homepage
                         featured_video_id about_me first_name last_name hobbies location
                         occupation school subscriber_count thumbnail username total_upload_views
                         }

end

String.extend Aji::RandomString
String.send :include, Aji::StringTokenizer
