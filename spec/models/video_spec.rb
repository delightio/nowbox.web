require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Video do
  describe "#thumbnail_uri" do
    it "should always have a uri if source is youtub" do
      video = Factory :video, :source=>:youtube
      video.thumbnail_uri.should include "youtube"
    end
  end
end

