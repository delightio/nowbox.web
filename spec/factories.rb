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

def random_video_action
  Aji::Event.video_actions.sample
end

def random_channel_action
  Aji::Event.channel_actions.sample
end

def random_video_source
  [:youtube].sample
end

def random_boolean
  [true, false].sample
end

Factory.define :user, :class => 'Aji::User' do |a|
  a.email { random_email }
  a.name { random_string }
end

Factory.define :user_with_channels, :parent =>:user do |a|
  a.after_create do |u|
    (2+rand(10)).times do |n|
      Factory :event, :user => u, :action => :subscribe,
        :channel => (Factory :youtube_channel_with_videos)
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
  a.action { random_video_action }
end

Factory.define :channel_event, :class => 'Aji::Event' do |a|
  a.association :user
  a.association :channel
  a.action { random_channel_action }
end

Factory.define :channel, :class => 'Aji::Channel' do |a|
  a.title { random_string }
  a.default_listing { random_boolean }
  # a.category { random_category }
end

Factory.define :youtube_channel, :class => 'Aji::Channel::Account' do |a|
  a.title { random_string }
  a.default_listing { random_boolean }
  a.after_create do |c|
    2.times do |n|
      c.accounts << (Factory :youtube_account_with_videos)
    end
  end
end

Factory.define :twitter_channel, :class => 'Aji::Channel::Account' do |a|
  a.title { random_string }
  a.default_listing { random_boolean }
  # a.category { random_category }
  a.after_create do |c|
    2.times do |n|
      c.accounts << (Factory :twitter_account)
    end
  end
end

Factory.define :keyword_channel, :class => 'Aji::Channel::Keyword' do |a|
  a.keywords { Array.new(5){|n| random_string} }
  a.default_listing { random_boolean }
  # a.category { random_category }
end


Factory.define :youtube_channel_with_videos, :parent => :youtube_channel do |a|
  # a.after_create do |c|
  #   5.times do |n|
  #     video = Factory :populated_video
  #     c.push video
  #     c.accounts << video.author
  #     c.update_relevance_in_categories [video]
  #   end
  # end
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

Factory.define :twitter_account,
  :class => 'Aji::Account::Twitter' do |a|
    a.uid { random_string }
    a.username { random_string }
  end

Factory.define :youtube_account_with_videos,
  :parent => :youtube_account do |a|
    a.after_create do |ea|
      3.times { ea.push(Factory :video) }
    end
  end

Factory.define :mention, :class => 'Aji::Mention' do |m|
  m.published_at { rand(10000).seconds.ago }
  m.association :author, :factory => :twitter_account
  m.sequence(:uid) { |n| n.to_s }
end
