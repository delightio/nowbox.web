require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Category do
    subject { Category.create.tap{|c| c.channel_id_zset[1]=1 } }

    it_behaves_like "any redis object model"
    it_behaves_like "any featured model"

    it "sets title as raw_title after create" do
      c = Aji::Category.find_or_create_by_raw_title random_string
      c.title.should_not be_nil
    end

    describe "#featured_channels" do
      subject { Aji::Category.create :raw_title => random_string }
      it "returns channels which top categories are also self" do
        ch1 = Factory :channel
        ch1.stub(:category_ids).and_return([subject.id])
        ch2 = Factory :channel
        ch2.stub(:category_ids).
          and_return([(Factory :category).id])
        Aji::Channel.stub(:find).with(ch1.id).and_return ch1
        Aji::Channel.stub(:find).with(ch2.id).and_return ch2
        subject.stub(:channel_ids).and_return([ch1.id, ch2.id])

        featured = subject.featured_channels
        featured.should include ch1
        featured.should_not include ch2
      end
    end
  end
end
