require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::FacebookStream do
    before :each do
      # TODO: This is pretty indicative that #refresh_content needs to be
      # refactored.
      video = mock "video", :populate => true, :populated? => true
      mention = mock "mention", :videos => Array.new(1, @video)
      api = mock "FacebookAPI"
      api.stub(:video_mentions_in_feed).and_return Array.new 3, mention
      @owner = mock "Facebook Account", :api => @api
    end
    subject { Channel::FacebookStream.create :owner => @owner }
    it_behaves_like "any channel"
  end
end
