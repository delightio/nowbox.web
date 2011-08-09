require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Category do
  subject { Aji::Category.create :title => Aji::Category.random_string_ }
  it "has an id, title and a list of associated channels" do
    20.times { |n| Factory :youtube_channel }
    subject.id.should be_a_kind_of(Numeric)
    subject.title.should be_a_kind_of(String)
    subject.channel_ids.should be_a_kind_of(Array)
    subject.channel_ids.each  do |cid|
      Aji::Channel.find(cid).should_not be_nil
    end
  end
end
