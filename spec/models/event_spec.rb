require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Event do
  describe "#create" do
    it "triggers caching for user" do
      Aji::User.any_instance.should_receive(:process_event).
        with(an_instance_of(Aji::Event))
      event = Factory :event, :action => :view
    end

    context "When asked to examine video" do
      it "queues the given video in queue" do
        Resque.should_receive(:enqueue).with(
          Aji::Queues::ExamineVideo, an_instance_of(Hash))
        event = Factory :event, :action => :examine,
          :reason => random_string
      end

      it "saves the reason" do
        reason = random_string
        Resque.should_receive(:enqueue).with(
          Aji::Queues::ExamineVideo, an_instance_of(Hash))
        event = Factory :event, :action => :examine,
          :reason => reason
        Aji::Event.find(event.id).reason.should == reason
      end

    end
  end
end
