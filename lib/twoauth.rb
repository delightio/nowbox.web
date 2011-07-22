require 'oauth'
require 'pp'

module Twoauth
  def Twoauth.prepare_access_token(oauth_token, oauth_token_secret)
    consumer = OAuth::Consumer.new(Aji.conf['CONSUMER_KEY'],
                                   Aji.conf['CONSUMER_SECRET'],
                                   { :site => "http://api.twitter.com",
                                     :scheme => :header })
    # now create the access token object from passed values
    token_hash = { :oauth_token => oauth_token, :oauth_token_secret => oauth_token_secret }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
    return access_token
  end

  def Twoauth.get_nm_token
    prepare_access_token(Aji.conf['OAUTH_TOKEN'],
                         Aji.conf['OAUTH_TOKEN_SECRET'])
  end
end

