require_relative '../aji'

jsonfilename = "#{Aji.root}/config/channels.json"
json = File.open jsonfilename
channels_json = JSON.parse json.read
raise "Can't parse #{jsonfilename}" if channels_json.nil?
channels_json.each do |ch|
  puts "Creating #{ch["title"]} channel with #{ch["usernames"].count} #{ch["type"]} accounts: #{ch["usernames"]}..."
  raise "Can't deal with type #{ch["type"]}" if ch["type"]!="youtube"

  start = Time.now
  channel = Aji::Channel::YoutubeAccount.find_or_create_by_usernames(
    ch["usernames"],
    :title => ch["title"],
    :category => ch["category"],
    :default_listing => true,
    :populate_if_new => true)
  puts "  => #{channel.inspect} in #{Time.now-start} s."
  if channel.save != true
    puts "*** error saving #{channel.title} because: #{channel.errors}"
  end
  puts
end
