def random_string length = 10
  letters = ('a'..'z').to_a
  (0...length).map { letters[rand 26] }.join
end

def random_filename ext=nil
  ext ||= random_string(3)
  "#{random_string}.#{ext}"
end

def random_uuid
  Digest::MD5.hexdigest("#{rand(9999) + Time.now.to_i}")
end

def random_url
  "http://some.random.url/path/to/file/#{random_filename}"
end

def random_size; rand(1000000) * 1024; end

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
