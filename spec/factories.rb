FactoryGirl.define do
  sequence(:first_name) { |n| "Person##{n}" }
  sequence(:last_name) { |n| "Surname##{n}" }
  sequence(:title) { |n| "Video##{n}" }

  factory :user, :class => 'Aji::User' do
    first_name
    last_name
    email { "#{first_name}@#{last_name}.com".downcase }
  end

  # TODO: I believe this to be unnecessary. Will not remove until proven.
  factory :user_with_channels, :parent =>:user do |a|
    a.after_create do |u|
      (2+rand(10)).times do |n|
        c = Factory :channel_with_videos
        u.subscribe c
      end
    end
  end

  # TODO: I believe this to be unnecessary. Will not remove until proven.
  factory :user_with_viewed_videos, :parent => :user do |a|
    a.after_create do |u|
      c = Factory :channel_with_videos
      c.content_videos.sample(10).each do |v|
        e = Factory :event, :video=>v, :channel=>c, :user=>u
      end
    end
  end

  factory :event, :class => 'Aji::Event' do
    user
    video
    channel
    video_elapsed { rand(100).to_f/(1+rand(100)) }
    event_type { Aji::Supported.event_types.sample }
  end

  factory :channel, :class => 'Aji::Channel' do
    title
    default_listing { [true, false].sample }
    category { Aji::Supported.categories.sample }
  end

  # TODO: I believe this to be unnecessary. Will not remove until proven.
  factory :channel_with_videos, :parent => :channel do |a|
    a.after_create do |c|
      50.times do |n|
        c.push Factory :populated_video
      end
    end
  end

  factory :youtube_video, :class => 'Aji::Video' do
    source :youtube
    sequence(:external_id) { |n| "123456asdf#{n}" }
  end

  factory :vimeo_video, :class => 'Aji::Video' do
    source :vimeo
    sequence(:external_id) { |n| n.to_s }
  end

#factory :populated_video, :parent => :video do |a|
#  title
#  a.description { random_string(50) }
#  a.duration { rand(100) }
#  a.viewable_mobile true
#  a.view_count { rand(1000) }
#  a.published_at { Time.now - rand(10).days }
#  a.populated_at { Time.now }
#end

#factory :video_with_mentions, :parent => :video do |a|
#  a.after_create do |v|
#    10.times do |n|
#      m = Factory :mention
#      m.videos << v
#    end
#  end
#end

#factory :populated_video_with_mentions, :parent => :populated_video do |a|
#  a.after_create do |v|
#    10.times do |n|
#      m = Factory :mention
#      m.videos << v
#    end
#  end
#end

#factory :youtubeit_video, :class => 'YouTubeIt::Model::Video' do |a|
#  a.width { rand(100) }
#  a.height { rand(100) }
#  a.title { random_string }
#  a.description { random_string(50) }
#  a.duration { rand(100) }
#  a.noembed { random_boolean }
#  a.view_count { rand(1000) }
#  a.published_at { Time.now.to_s }
#end

#factory :external_account,
#  :class => 'Aji::ExternalAccounts::Youtube' do |a|
#    a.uid { random_string }
#    a.provider { random_video_source }
#  end

#factory :mention, :class => 'Aji::Mention' do |a|
#  published_at { rand(10000).seconds.ago }
#  association :author, :factory => :external_account
end
