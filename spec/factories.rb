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
  [ :view, :share, :upvote, :downvote ].sample
end

def random_video_source
  [:youtube].sample
end

Factory.define :user, :class => 'Aji::User' do |a|
  a.email { random_email }
end

Factory.define :event, :class => 'Aji::Event' do |a|
  a.association :user
  a.association :video
  a.association :channel
  a.video_elapsed { random_float }
  a.event_type { random_event_type }
end

Factory.define :channel, :class => 'Aji::Channel' do |a|
end

Factory.define :video, :class => 'Aji::Video' do |a|
  a.external_id { random_string }
  a.source { random_video_source }
  a.title { random_string }
  a.description { random_string(50) }
  a.viewable_mobile true
  a.association :external_account
end

Factory.define :external_account,
  :class => 'Aji::ExternalAccounts::Youtube' do |a|
    a.uid { random_string }
    a.provider { random_video_source }
  end
