module Aji
  class Parsers::FBLink
    def self.parse post
      filter = if block_given? then yield post else true end
      return nil unless filter

      author = Account::Facebook.find_or_create_by_uid(post['from']['id'],
        :info => post['from'])

      Mention.create_or_find_by_uid_and_source post['id'], 'facebook',
        :body => post['message'],
        :published_at => post['created_time'],
        :author => author,
        :links => Array(Link.new post['link']),
    end
  end
end
