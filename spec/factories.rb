def random_string length = 10
  letters = ('a'..'z').to_a
  (0...length).map { letters[rand 26] }.join
end

def random_float
  rand(100).to_f/(1+rand(100))
end

def random_email
  "#{random_string}@#{random_string(8)}.#{random_string(5)}.#{random_string(3)}"
end

def random_event_type
  Aji::Supported.event_types.sample
end

def random_video_source
  [:youtube].sample
end

def random_boolean
  [true, false].sample
end

# def random_category
#   Aji::Supported.categories.sample
# end

Factory.define :user, :class => 'Aji::User' do |a|
  a.email { random_email }
  a.first_name { random_string }
  a.last_name { random_string }
end

Factory.define :user_with_channels, :parent =>:user do |a|
  a.after_create do |u|
    (2+rand(10)).times do |n|
      c = Factory :youtube_channel_with_videos
      u.subscribe c
    end
  end
end

Factory.define :user_with_viewed_videos, :parent => :user do |a|
  a.after_create do |u|
    c = Factory :youtube_channel_with_videos
    c.content_videos.sample(10).each do |v|
      e = Factory :event, :video=>v, :channel=>c, :user=>u
    end
  end
end

Factory.define :event, :class => 'Aji::Event' do |a|
  a.association :user
  a.association :video
  a.association :channel
  a.video_elapsed { random_float }
  a.event_type { random_event_type }
end

Factory.define :channel, :class => 'Aji::Channel' do |a|
  a.title { random_string }
  a.default_listing { random_boolean }
  # a.category { random_category }
end

Factory.define :youtube_channel, :class => 'Aji::Channels::YoutubeAccount' do |a|
  a.title { random_string }
  a.default_listing { random_boolean }
  # a.category { random_category }
end

Factory.define :keyword_channel, :class => 'Aji::Channels::Keyword' do |a|
  a.keywords { Array.new(5){|n| random_string} }
  a.default_listing { random_boolean }
  # a.category { random_category }
end


Factory.define :youtube_channel_with_videos, :parent => :youtube_channel do |a|
  a.after_create do |c|
    5.times do |n|
      video = Factory :populated_video
      c.push video
      c.accounts << video.author
      c.update_relevance_in_categories [video]
    end
  end
end

Factory.define :category, :class => 'Aji::Category' do |a|
  a.title { random_string }
  a.raw_title { random_string }
end

Factory.define :video, :class => 'Aji::Video' do |a|
  a.external_id { random_string }
  a.source { random_video_source }
  a.association :author, :factory => :youtube_account
  a.after_create do |v|
    v.author.push v
  end
end

Factory.define :populated_video, :parent => :video do |a|
  a.title { random_string }
  a.description { random_string(50) }
  a.duration { rand(100) }
  a.viewable_mobile true
  a.view_count { rand(1000) }
  a.association :category, :factory => :category
  a.published_at { Time.now - rand(10).days }
  a.populated_at { Time.now }
end

Factory.define :video_with_mentions, :parent => :video do |a|
  a.after_create do |v|
    10.times do |n|
      m = Factory :mention
      m.videos << v
    end
  end
end

Factory.define :populated_video_with_mentions, :parent => :populated_video do |a|
  a.after_create do |v|
    10.times do |n|
      m = Factory :mention
      m.videos << v
    end
  end
end

Factory.define :account,
  :class => 'Aji::Account' do |a|
    a.uid { random_string }
  end

Factory.define :youtube_account,
    :class => 'Aji::Account::Youtube' do |a|
      a.uid { random_string }
    end

Factory.define :youtube_account_with_videos,
  :parent => :youtube_account do |a|
    a.after_create do |ea|
      ea.push(Factory :video)
    end
  end

Factory.define :mention, :class => 'Aji::Mention' do |a|
  a.published_at { rand(10000).seconds.ago }
  a.association :author, :factory => :account
end
