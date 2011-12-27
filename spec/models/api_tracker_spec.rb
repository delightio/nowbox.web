require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::APITracker, :unit do
    let(:cooldown) { 100 }
    let(:hits_per_session) { 10 }
    let(:method_limits) { { post: 0.1 } }
    let(:key_name) { "api_tracker:spec" }
    let(:redis) { Aji.redis }
    subject do
      APITracker.new "spec", redis, cooldown: cooldown,
      hits_per_session: hits_per_session, method_limits: method_limits
    end

    describe "#hit" do
      it "increases the hit count" do
        expect{ subject.hit }.to change{ subject.hit_count }.by(1)
      end

      let(:api_method) { :get }
      it "records throttle reason and raises an error when not aviailable" do
        subject.stub :available? => false
        subject.should_receive(:close_session!).
          with("available? #{api_method} => false")

        expect{ subject.hit(api_method) }.to raise_error APITracker::LimitReached
      end

      it "executes an optional block unless the rate limit is exceeded" do
        mutable_variable = :unchanged
        subject.hit { mutable_variable = :changed }
        mutable_variable.should == :changed
      end
    end

    describe "#hit!" do
      it "creates the redis key_name and expiration if it does not exists" do
        redis.should_receive(:hset).with(key_name, "count", 0)
        redis.should_receive(:expire).with(key_name, cooldown)
        subject.hit!
      end

      it "increments the count field if it already exists" do
        redis.hset(key_name, "count", 0)
        redis.should_receive(:hincrby).with(key_name, "count", 1)
        subject.hit!
      end

      it "increments the count field for an api method if given" do
        redis.should_receive(:hincrby).with(key_name, :get, 1)

        subject.hit! :get
      end
    end

    describe "#available?" do
      specify "true when the hit count is below the hits per session" do
        (hits_per_session - 1).times do
          subject.hit
          subject.should be_available
        end
      end

      specify "false when the api method has reached its quota" do
        subject.should_receive(:hit_count).with(:post).and_return(2)

        subject.should_not be_available(:post)
      end

      specify "false when the throttle key is set" do
        subject.close_session!

        subject.should_not be_available
      end

      specify "false when the hit count is greater than the hits per session" do
        subject.stub :hit_count => hits_per_session

        subject.should_not be_available
      end
    end

    describe "#seconds_until_available" do
      it "returns the remaining cooldown time in seconds" do
        redis.should_receive(:ttl).with(key_name).and_return(30)

        subject.seconds_until_available.should == 30
      end
    end

    describe "#hit_count" do
      it "returns the number of hits made during this session" do
        redis.should_receive(:hget).with(key_name, "count").
          and_return("7")
        subject.hit_count.should == 7
      end
    end

    describe "#reset_session!" do
      it "deletes the entire session hash" do
        subject.redis.should_receive(:del).with(key_name)
        subject.reset_session!
      end
    end

    describe "#close_session!" do
      let(:reason) { random_string }
      it "sets the throttle key and reason" do
        subject.redis.should_receive(:hset).
          with(key_name, subject.throttle_key, 'yes')
        subject.redis.should_receive(:hset).
          with(key_name, subject.throttle_reason_key, reason)

        subject.close_session! reason
      end

      it "resets the cool down period" do
        subject.redis.should_receive(:expire).with(key_name, cooldown)

        subject.close_session!
      end
    end

    describe "#key_name" do
      it "returns the prefixed key_name for the api" do
        subject.key.should == key_name
      end
    end
  end
end
