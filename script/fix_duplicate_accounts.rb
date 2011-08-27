require_relative '../aji'

Aji.log "Fixing duplicate accounts"
count_hash = Hash.new(0)
accounts = Aji::Account.select(:username).map(&:username).each do |u|
  count_hash[u] += 1
end

count_hash.each do |count, username|
  next if count < 2
  duped_accounts = Aji::Account.find_all_by_username username
  keep_me = duped_accounts.first
  duped_accounts[1..-1].each do |dupe|
    keep_me.mentions += dupe.mentions
    keep_me.save
    dupe.destroy
    Aji.log "Deleted Account[#{dupe.id}] with #{dupe.mentions.count} mentions" +
      " transfered to Account[#{keep_me.id}]"
  end
end
