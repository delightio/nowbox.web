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
end

#Factory.define :library_album, :class => 'Kampanchi::Album' do |a|
#  a.name  "Library"
#  a.album_type "system"
#end
#
#Factory.define :trash_album, :class => 'Kampanchi::Album' do |a|
#  a.name  "Trash"
#  a.album_type "system"
#end
#
#Factory.define :user, :class => 'Kampanchi::User' do |u|
#  u.name {random_string}
#end
#
#Factory.define :album, :class => 'Kampanchi::Album' do |a|
#  a.name {random_string}
#  a.after_create { |album| album.add_user(Factory :user) if album.users.count==0 }
#end
#
#Factory.define :invitation, :class => 'Kampanchi::Invitation' do |i|
#  i.code { (rand 9999).to_s }
#  i.after_build { |invitation| a = Factory :album; invitation.album=a; invitation.user=a.users.first}
#end
#
#Factory.define :media, :class => 'Kampanchi::Media' do |m|
#  m.file_name { random_filename }
#  m.size { random_size }
#  m.checksum { random_uuid }
#  m.owner { Factory(:user).id }
#  m.after_create { |media| media.add_album(Factory :album) }
#end
