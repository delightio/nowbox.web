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
  end
end
