require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Event do
  describe "#create" do
    it "should trigger caching for user" do
      event = Factory :event, :event_type => :view
      event.user.viewed.members.should include event.video.id.to_s
    end
  end
end
