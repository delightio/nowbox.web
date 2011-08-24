require File.expand_path("../../spec_helper", __FILE__)
module Aji
  describe Queues::ExamineVideo do
    subject { Queues::ExamineVideo }
    describe ".perform" do
      it "exits silently if given video is invalid" do
        expect { subject.perform Hash.new }.to_not raise_error
      end

      it "blacklists if video is valid" do
        args = {
          :user_id => (Factory :user).id,
          :channel_id => (Factory :channel).id,
          :video_id => (Factory :video).id }
        expect { subject.perform args }.
          to change { Video.find(args[:video_id]).blacklisted? }.
          to true
      end

      it "blacklists author if more than 3 of his videos are blacklisted" do
        bad_author = Factory :youtube_account
        5.times do
          video = Factory :video, :author => bad_author
          video.blacklist
        end
        args = {
          :user_id => (Factory :user).id,
          :channel_id => (Factory :channel).id,
          :video_id => (bad_author.content_videos.sample).id }
        expect { subject.perform args }.
          to change { bad_author.reload.blacklisted? }.
          to true
      end

    end
  end
end