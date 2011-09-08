require_relative '../aji'

# Create the trending channel by invoking the singleton.
puts "Creating Trending Channel with ID:#{Aji::Channel.trending}"

jsonfilename = "#{Aji.root}/config/channels.json"
json = File.open jsonfilename
channels_json = JSON.parse json.read
raise "Can't parse #{jsonfilename}" if channels_json.nil?
channels = []
channels_json.each do |ch|
  puts "Creating #{ch["title"]} channel with #{ch["usernames"].count} #{ch["type"]} accounts: #{ch["usernames"]}..."
  raise "Can't deal with type #{ch["type"]}" if ch["type"]!="youtube"

  accounts = ch['usernames'].map do |u|
    Aji::Account::Youtube.find_or_create_by_uid u
  end

  channel = Aji::Channel::Account.find_by_title ch["title"]
  if channel
    puts "Updating previous channel, #{ch["title"]}, with #{accounts.count-channel.accounts.count} more accounts"
    channel.accounts = accounts
  else
    channel = Aji::Channel::Account.find_or_create_by_accounts(
      accounts, { :title => ch["title"], :default_listing => true })
  end
  puts "  => #{channel.inspect}"
  if channel.save != true
    puts "*** error saving #{channel.title} because: #{channel.errors}"
  end
  channels << channel
  Resque.enqueue Aji::Queues::RefreshChannel, channel.id
  puts

  # Also create individial
  accounts.each do |account|
    channel = Aji::Channel::Account.find_or_create_by_accounts [account]
    channels << channel
    puts "  Created #{channel.accounts.first.username}'s channel: #{channel.inspect}"
  end
  puts

end

puts
puts "*** Created #{channels.count} channels. Enqueuing them for refresh..."
channels.each {|c| Resque.enqueue Aji::Queues::RefreshChannel, c.id}