require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Account::Youtube do
    subject { Account::Youtube.create :uid => "freddiew" }
    it_behaves_like "any account"

    describe "#existing?" do
      it "is false for non existing youtube account" do
        a = Account::Youtube.new :uid => "doesntexist"
        a.api.should_receive(:valid_uid?).and_return(false)
        a.should_not be_existing
      end

      it "is true for existing youtube account" do
        subject.api.should_receive(:valid_uid?).and_return(true)
        subject.should be_existing
      end
    end

    describe "#get_info_from_youtube_api" do
      it "uses the youtube api to get author info" do
        subject { Account::Youtube.new :uid => 'day9tv' }
        subject.api.should_receive(:author_info).with(subject.uid)
        subject.get_info_from_youtube_api
      end
    end

    describe ".create_if_existing" do
      let(:uid) { "anything" }

      it "returns db copy if we have it" do
        a = Account::Youtube.create :uid=>uid
        Account::Youtube.create_if_existing(uid).should == a
      end

      it "does not create new object if given uid is invalid" do
        a = mock("account", :existing? => false)
        Account::Youtube.stub(:new).with(:uid=>uid).and_return(a)
        Account::Youtube.create_if_existing(uid).should be_nil
      end

      it "creates a new object if given uid is valid but not already in db" do
        a = mock("account", :existing? => true)
        Account::Youtube.should_receive(:find_or_create_by_uid).
          with(uid).and_return(mock)
        Account::Youtube.create_if_existing uid
      end

    end

  end
end
