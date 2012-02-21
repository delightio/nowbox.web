require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Event, :unit do
  describe ".create_video_if_needed" do
    let(:video) { mock :id => 10, :external_id => '2wjh0N1EzPI', :source => :youtube}
    let(:video_params) {{ :action => :view,
                          :video_external_id => video.external_id,
                          :video_source => :youtube} }

    it "creates video object if video action" do
      Video.should_receive(:find_or_create_by_source_and_external_id).
        with(video.source, video.external_id).
        and_return(video)

      parsed = Event.parse_params video_params
      parsed.should have_key :video_id
      parsed[:video_id].should == video.id

      parsed.should_not have_key :video_source
      parsed.should_not have_key :video_external_id
    end
  end

  describe ".parse_params" do
    let(:params) { mock }
    it "creates video object if needed" do
      Event.should_receive(:create_video_if_needed).with(params).and_return(params)
      Event.parse_params params
    end
  end

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
