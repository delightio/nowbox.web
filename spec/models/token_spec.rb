require File.expand_path("../../spec_helper", __FILE__)

include Aji

describe Aji::Token do
  describe Aji::Token::Generator do
    subject { Token::Generator.new user } 
    let(:user) { mock "user", :id => 11 }

    describe "#generate_token!" do
      it "sets the token to a string of 32 random word characters" do
        subject.send :generate_token!
        subject.token.should match /\w{32}/
      end

      it "stores the token" do
        subject.should_receive(:store_token)

        subject.send :generate_token!
      end
    end

    describe "#store_token" do
      it "stores the token in redis" do
        subject.instance_variable_set :@token, "asdf"

        Aji.redis.should_receive(:set).with("authentication:asdf", user.id)
        Aji.redis.should_receive(:expire).with("authentication:asdf", 1.hour)

        subject.send :store_token
      end

      it "expires the token in an hour" do
        subject.expires_at.should < 1.hour.from_now
        subject.expires_at.should > 1.hour.from_now - 10.seconds
      end
    end
  end

  describe Token::Validator do
    specify "when the token is valid for the user" do
      subject.should be_valid?
    end

    specify "when the token is not for this user" do
      subject.should_not be_valid
      subject.should be_incorrect
    end

   specify "when the token is invalid" do
      subject.should_not be_valid
      subject.should_not be_incorrect
    end
  end
end

