require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::EmailCollectors do
  describe Aji::Mixins::EmailCollectors::Facebook do
    subject { Class.new { include Aji::Mixins::EmailCollectors::Facebook }.new }

    let(:email) { "jkjl@kljlkj.com" }
    it "saves email to redis if email is present" do
      subject.stub :email => email
      Aji::redis.should_receive(:sadd).with(subject.email_collector_key, email)

      subject.collect_email
    end

    it "does not save to redis if email isn't present" do
      subject.stub :email => nil
      Aji::redis.should_not_receive :sadd

      subject.collect_email
    end
  end
end