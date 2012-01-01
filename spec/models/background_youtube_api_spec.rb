require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe BackgroundYoutubeAPI do
  subject { BackgroundYoutubeAPI.new stub, stub, stub }

  context "if POST calls" do
    let(:post_action) { :subscribe_to }
    let(:post_args) { stub }

    describe "#method_missing" do
      it "uses a background queue to process given action" do
        Resque.should_receive(:enqueue).
          with(Queues::BackgroundYoutubeRequest,
            an_instance_of(Hash), post_action, post_args)

        subject.send post_action, post_args
      end
    end
  end

  context "if GET calls" do
    let(:get_action) { :subscriptions }

    describe "#method_missing" do
      let(:api) { subject.instance_variable_get(:@api) }

      context "if no more API quota" do
        before :each do
          api.tracker.stub :availabe? => false
        end

        it "adds to missed calls" do
          api.tracker.should_receive(:add_missed_call)

          subject.send get_action
        end

        it "returns default_return based on method call" do
          api.should_receive(:default_return).with(get_action)

          subject.send get_action
        end
      end

      context "if API throws an error" do
        before :each do
          api.should_receive(:send).with(get_action).
            and_return {raise AuthenticationError, "too_many_recent_calls"}
        end

        it "adds to missed calls" do
          api.tracker.should_receive(:add_missed_call)

          subject.send get_action
        end

        it "close session on tracker" do
          api.tracker.should_receive(:close_session!)

          subject.send get_action
        end

        it "returns default return based on method call" do
          api.should_receive(:default_return).with(get_action)

          subject.send get_action
        end
      end
    end
  end
end