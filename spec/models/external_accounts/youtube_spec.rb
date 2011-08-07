require File.expand_path("../../../spec_helper", __FILE__)
module Aji
  describe ExternalAccounts::Youtube do
    describe "#populate" do
      subject { ExternalAccounts::Youtube.find_or_create_by_uid "nowmov" }

      it "populates new account" do
        subject.content_videos.should be_empty
        subject.populate
        subject.content_videos.should_not be_empty
      end

      it "does not re populate within short time" do
        subject.should_receive(:save).once
        subject.populate
        subject.should_not_receive(:save)
        subject.populate
      end

      it "allows forced population" do
        subject.populate
        subject.should_receive(:save).once
        subject.populate :must_populate=>true
      end

      it "waits for the lock before populating"
    end
  end
end
