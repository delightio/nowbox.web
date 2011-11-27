require File.expand_path("../../spec_helper", __FILE__)
include Aji

describe Recommendation do

  let(:video11) { stub id: 10 }
  let(:video12) { stub id: 20 }
  let(:channel1) { stub content_videos: [video11, video12] }
  let(:video21) { stub id: 30 }
  let(:channel2) { stub content_videos: [video21] }
  let(:channels) { [ channel1, channel2 ]}
  let(:user) { u = User.create; u.stub subscribed_channels: channels; u }
  subject { Recommendation.new user }

  describe "#videos" do
    it "returns a list of latest videos from user's subscribed channels)" do
      Set.new(subject.videos).should == Set.new(channel1.content_videos +
                                                channel2.content_videos)
    end
  end

  describe "#refresh_videos" do
    it "pushes recommended videos to given channel" do
      subject.videos.each do |v|
        user.recommended_channel.should_receive(:push).with(v).once
      end
      user.recommended_channel.should_receive(:update_attribute).
        with(:populated_at, an_instance_of(Time))

      subject.refresh_videos
    end

    it "does not update given channel if channel has been recently refreshed" do
      user.recommended_channel.stub :recently_populated? => true
      user.recommended_channel.should_not_receive(:push)

      subject.refresh_videos
    end
  end

  describe "#background_refresh" do
    it "sets up a resque job to run recommendation" do
      Resque.should_receive(:enqueue_in).with(
        1.hour, Aji::Queues::RefreshRecommendedVideos, user.id)

      subject.background_refresh
    end
  end

end