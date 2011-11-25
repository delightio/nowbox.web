require File.expand_path("../../../spec_helper", __FILE__)
include Aji

describe Channel::Recommended do
  subject { Channel::Recommended.create }

  describe "#available?" do
    it "is always unavailable for search" do
      subject.should_not be_available
    end
  end

  describe "#refresh_content" do
    it "is no-op" do
      expect { subject.refresh_content :force }.
        to_not change { subject.content_videos.count }
    end
  end

end