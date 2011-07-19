jsonfilename = "#{Aji.root}/config/channels.json"
json = File.open jsonfilename
channels_json = JSON.parse json.read
raise "Can't parse #{jsonfilename}" if channels_json.nil?
channels_json.each do |ch|
  puts "Creating #{ch["title"]} channel with #{ch["usernames"].count} #{ch["type"]} accounts: #{ch["usernames"]}..."
  raise "Can't deal with type #{ch["type"]}" if ch["type"]!="youtube"
  
  channel = Aji::Channels::YoutubeAccount.find_or_create_by_usernames(
    ch["usernames"],
    :title => ch["title"], :populate_if_new => true)
  puts "  => #{channel.inspect}"
end