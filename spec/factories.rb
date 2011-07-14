FactoryGirl.define do
    sequence(:first_name) { |n| "Person##{n}" }
    sequence(:last_name) { |n| "Surname##{n}" }
end

Factory.define :user, :class => 'Aji::User' do
  first_name
  last_name
  email { "#{first_name}@#{last_name}.com" }
end

Factory.define :user_with_channels, :parent =>:user do |a|
  a.after_create do |u|
    (2+rand(10)).times do |n|
      c = Factory :channel_with_videos
      u.subscribe c
    end
  end
end

Factory.define :user_with_viewed_videos, :parent => :user do |a|
  a.after_create do |u|
    c = Factory :channel_with_videos
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
  a.category { random_category }
end

Factory.define :channel_with_videos, :parent => :channel do |a|
  a.after_create do |c|
    50.times do |n|
      c.push Factory :populated_video
    end
  end
end

Factory.define :trending_channel, :class => 'Aji::Channels::Trending' do |a|
end

Factory.define :video, :class => 'Aji::Video' do |a|
  a.external_id { random_string }
  a.source { random_video_source }
  a.association :external_account
end

Factory.define :populated_video, :parent => :video do |a|
  a.title { random_string }
  a.description { random_string(50) }
  a.duration { rand(100) }
  a.viewable_mobile true
  a.view_count { rand(1000) }
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

Factory.define :youtubeit_video, :class => 'YouTubeIt::Model::Video' do |a|
  a.width { rand(100) }
  a.height { rand(100) }
  a.title { random_string }
  a.description { random_string(50) }
  a.duration { rand(100) }
  a.noembed { random_boolean }
  a.view_count { rand(1000) }
  a.published_at { Time.now.to_s }
end

Factory.define :external_account,
  :class => 'Aji::ExternalAccounts::Youtube' do |a|
    a.uid { random_string }
    a.provider { random_video_source }
  end
  
Factory.define :mention, :class => 'Aji::Mention' do |a|
  a.published_at { rand(10000).seconds.ago }
  a.association :author, :factory => :external_account
end
