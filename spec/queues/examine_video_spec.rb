require File.expand_path("../../spec_helper", __FILE__)
module Aji
  describe Queues::ExamineVideo do
    subject { Queues::ExamineVideo }
    describe ".perform" do

      let(:user) { mock("user", :id=>1) }
      let(:channel) { mock("channel", :id=>1) }
      let(:author) { mock("author", :id=>1, :blacklist_repeated_offender=>nil) }
      let(:video) { mock("video", :id=>1, :author=>author) }
      let(:args) { {:user_id=>user.id, :channel_id=>channel.id, :video_id=>video.id} }

      it "exits silently if given video is invalid" do
        expect { subject.perform Hash.new }.to_not raise_error
      end

      it "blacklists video and/or author" do
        Video.stub(:find_by_id).and_return(video)
        video.should_receive(:blacklist).once
        author.should_receive(:blacklist_repeated_offender)
        subject.perform args
      end

    end
  end
end