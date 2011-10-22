require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Event, :unit do
  describe "#process" do
    let(:user) { mock "user", :id => 1, :process_event => true }
    let(:video) { mock "video", :id => 2 }
    let(:channel) { mock "video", :id => 3 }

    subject do
      Event.new do |e|
        e.stub :user => user
        e.stub :video => video
        e.stub :channel => channel
      end
    end

    it "sends the event to the user for processing" do
      user.should_receive(:process_event).with(subject)

      subject.send :process
    end

    context "when an examine action is sent" do
      it "enqueues the video for examination in background" do
        subject.action = :examine
        subject.reason = "I hate squirrels"

        Resque.should_receive(:enqueue).with(
          Aji::Queues::ExamineVideo,{ :user_id => user.id,
          :video_id => video.id, :channel_id => channel.id,
          :reason => subject.reason })

        subject.send :process
      end
    end
  end
end
