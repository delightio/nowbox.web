require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe TrendingSource do
  let(:max_video_count) { 10 }
  let(:redis_url) { "url://random/" }
  let(:trending_zset_key) { "key" }
  let(:config) { {redis_url: redis_url,
                  trending_zset_key: trending_zset_key,
                  max_video_count: max_video_count}}
  subject { TrendingSource.new config }

  describe "#initialize" do
    it "connects to external redis" do
      subject.redis.should_not be_nil
    end
  end

  describe "#connnect" do
    it "connects external redis"
  end

  describe "#video_uids" do
    it "grabs video external ids according to given count" do
      subject.redis.should_receive(:zrevrange).
        with(trending_zset_key, 0, (max_video_count-1))

      subject.video_uids
    end
  end

  describe "#refresh" do
    let(:video1) { Video.create :external_id => 'abc', :source => subject.video_source }
    before :each do
      Video.stub(:find_or_create_by_source_and_external_id).
        with(subject.video_source, video1.external_id).
        and_return(video1)
      subject.stub :video_uids => [ video1.external_id ]
    end

    it "populates all videos" do
      video1.should_receive :populate

      subject.refresh
    end

    it "updates trending videos in each category"
  end
end