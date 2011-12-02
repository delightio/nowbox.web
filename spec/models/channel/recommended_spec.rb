require File.expand_path("../../../spec_helper", __FILE__)
include Aji

describe Channel::Recommended do
  subject { Channel::Recommended.create }

  let(:channel1) { Channel::Account.create }
  let(:channel2) { Channel::Account.create }
  let(:user) {
    u = User.create
    u.stub :subscribed_channels => [channel1, channel2]
    u
  }
  before(:each) do
    channel1.push Video.create(:source => :youtube,
      :external_id => 'afakevideo1')
    channel2.push Video.create(:source => :youtube,
      :external_id => 'afakevideo2')
    subject.stub :user => user
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

    it "goes thru all user subscribed channels" do
      user.should_receive :subscribed_channels
      Aji.redis.should_receive(:zunionstore).
        with(subject.content_zset.key, an_instance_of(Array))
      Aji.redis.should_receive(:expire).
        with(subject.content_zset.key, subject.content_zset_ttl)

      ids = subject.content_video_ids
    end

    it "uses cached versions if it has not been expired" do
      ids = subject.content_video_ids
      user.should_not_receive :subscribed_channels

      ids = subject.content_video_ids
    end
  end

end