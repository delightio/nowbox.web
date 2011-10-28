require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe YoutubeSync do
  it "subscribes the user to all account's youtube subscription"
  it "subscribes the account to all the user's youtube channels"

  it "adds youtube watch later to the user's queue_channel"
  it "adds videos from the user's queue channel to watch later"

  it "favorites videos from the user's favorites channel on youtube"
  it "favorites videos from youtube on the user's favorites channel"

  it "unsubscribes from youtube channels when they're unsubscribed locally"
  it "unsubscribes from youtube channels when they're unsubscribed locally"

  it "creates a link between a youtube account and a user"
end
