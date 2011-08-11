require File.expand_path("../../../spec_helper", __FILE__)
module Aji
  describe Account::Youtube do
    describe "#refresh_content" do
      subject { Account::Youtube.find_or_create_by_uid "nowmov" }

      it "populates new account" do
        subject.content_videos.should be_empty
        subject.refresh_content
        subject.content_videos.should_not be_empty
      end

      it "does not refresh_content within short time" do
        subject.should_receive(:save).once
        subject.refresh_content
        subject.should_not_receive(:save)
        subject.refresh_content
      end

      it "allows a forced refresh_content" do
        subject.refresh_content
        subject.should_receive(:save).once
        subject.refresh_content true
      end

      it "waits for the lock before populating"
    end

    describe "#thumbnail_uri" do
      it "returns a uri from Youtube API"
      it "replaces default blue ghost with first video" do
        pending "Check for default pic url and replace with our own or vid thumb"
      end
    end
  end
end
