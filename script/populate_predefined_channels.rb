require_relative '../aji'

jsonfilename = "#{Aji.root}/config/channels.json"
json = File.open jsonfilename
channels_json = JSON.parse json.read
raise "Can't parse #{jsonfilename}" if channels_json.nil?
channels_json.each do |ch|
  puts "Creating #{ch["title"]} channel with #{ch["usernames"].count} #{ch["type"]} accounts: #{ch["usernames"]}..."
  raise "Can't deal with type #{ch["type"]}" if ch["type"]!="youtube"

  accounts = ch['usernames'].map do |u|
    Aji::Account::Youtube.find_or_create_by_uid u
  end

  start = Time.now
  channel = Aji::Channel::Account.find_or_create_by_accounts(
    accounts, { :title => ch["title"], :default_listing => true }, true)
  puts "  => #{channel.inspect} in #{Time.now-start} s."
  if channel.save != true
    puts "*** error saving #{channel.title} because: #{channel.errors}"
  end
  puts
end
