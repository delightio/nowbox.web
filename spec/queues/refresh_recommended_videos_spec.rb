require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Queues::RefreshRecommendedVideos do
    let(:user) { User.create }
    subject { Queues::RefreshRecommendedVideos }

    describe ".perform" do
      it "skips if user no longer exisits" do
        Recommendation.should_not_receive(:new)
        subject.perform user.id+1
      end

      it "refreshes recommendation videos" do
        recommendation = stub
        Recommendation.should_receive(:new).with(user).
          and_return(recommendation)
        recommendation.should_receive(:refresh_videos)
        subject.perform user.id
      end

    end
  end
end
