require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Category do
  subject { Aji::Category.create(
    :title => random_string, :raw_title => random_string) }

  it "has an id, title, label and a list of associated channels" do
    20.times { |n| Factory :youtube_channel }
    subject.id.should be_a_kind_of(Numeric)
    subject.title.should be_a_kind_of(String)
    subject.raw_title.should be_a_kind_of(String)
    subject.channel_ids.should be_a_kind_of(Array)
    subject.channel_ids.each  do |cid|
      Aji::Channel.find(cid).should_not be_nil
    end
  end

  it "sets title as raw_title after create" do
    c = Aji::Category.find_or_create_by_raw_title random_string
    c.title.should_not be_nil
  end

end
