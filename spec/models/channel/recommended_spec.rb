require File.expand_path("../../../spec_helper", __FILE__)
include Aji

describe Channel::Recommended do
  subject { Channel::Recommended.create }

  let(:author1) { Account.create uid: "author1" }
  let(:author2) { Account.create uid: "author2"}
  let(:video1) {
    Video.create(:source => :youtube,
      :external_id => 'afakevideo1',
      :author => author1)
  }
  let(:video2) {
    Video.create(:source => :youtube,
      :external_id => 'afakevideo2',
      :author => author2)
  }
  let(:channel1) { author1.to_channel }
  let(:channel2) { author2.to_channel }

  let(:user) {
    User.create.tap do |u|
      [channel1, channel2].each {|ch| u.subscribe ch}
    end
  }
  before(:each) do
    channel1.push video1, 1.minutes.ago
    channel2.push video2, 2.minutes.ago
    user.recommended_channel = subject
    user.save
  end

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

  describe "#content_video_ids" do
    it "uses cached versions if it has not been expired" do
      ids = subject.content_video_ids
      user.should_not_receive :subscribed_channels

      ids = subject.content_video_ids
    end

    it "truncates to only 20 videos" do
      subject.should_receive(:truncate).with(20)

      subject.content_video_ids
    end

    context "when there were events" do
      let(:another_video) { Video.create(:source => :youtube, :external_id => 'afakevideo3') }
      it "ranks one by events associated with the given channel" do
        viewed = Event.create(:user => user, :channel => channel2,
          :video => another_video, :video_elapsed => 14.023,
          :action => :view)

        subject.content_video_ids.should == [video2.id, video1.id]
      end
    end

    context "when no events were done in the recent videos" do
      it "returns latest videos first" do
        subject.content_video_ids.should == [video1.id, video2.id]
      end
    end
  end

end