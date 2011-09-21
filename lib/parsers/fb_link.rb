module Aji
  class Parsers::FBLink
    def self.parse post
      filter = if block_given? then yield post else true end
      return nil unless filter

      author = Account::Facebook.find_or_create_by_uid(post['from']['id'])

      Mention.new(
        :uid => post['id'],
        :body => post['message'],
        :published_at => post['created_time'],
        :author => author,
        :links => Array(Link.new post['link']),
        :source => 'facebook'
      )
    end
  end
end
