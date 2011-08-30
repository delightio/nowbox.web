require_relative '../aji'

Aji.log "Repairing Mentions with Nil Authors"

nil_author_mentions = Aji::Mention.where(:author_id => nil).select(
  [ :id, :unparsed_data ])

Aji.log :WARN, "Found #{nil_author_mentions.count} mentions with nil authors."

nil_author_mentions.each do |m|
  user = MultiJson.decode(m.unparsed_data)['user']
  account = Aji::Account::Twitter.find_by_username user['screen_name']
  unless account.nil?
    Aji.log :WARN, "#{account.username} existed in DB but wasn't linked to " +
      "Mention[#{m.id}]"
  else
    Aji.log :WARN, "No account was created for #{user['screen_name']}."
    account = Aji::Account::Twitter.create :username => user['screen_name'],
      :uid => user['id'], :info => user
  end

  m.author = account
  if m.save
    Aji.log "Linked Mention[#{m.id}] with Account[#{account.id}]"
  else
    Aji.log :WTF, "Unable to link Mention[#{m.id}] with " +
      "Account[#{account.id}]. Please check!"
  end
end

nil_author_videos = Aji::Video.where "author_id = NULL AND populated_at != NULL"

Aji.log :WARN, "Found #{nil_author_videos.count} videos with nil authors."

nil_author_videos.each do |v|
  v.populate
  Aji.log :WTF, "Error repopulating author of Video[#{v.id}]" if v.author.nil?

  v.save or Aji.log :WARN, "Unable to save Video[#{v.id}]"
end
