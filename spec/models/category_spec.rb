require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Category, unit: true do
    subject do
      Category.new.tap do |c|
        c.stub :id => 1
        c.channel_id_zset[1]=1
        Category.stub(:find_by_id).with(c.id).and_return(c)
        Category.stub(:find_by_id).with([c.id]).and_return([c])
        Category.stub(:find_by_title).and_return(c)
      end
    end

    it_behaves_like "any redis object model"
    it_behaves_like "any featured model"

    it "sets title as raw_title after create" do
      c = Category.create :raw_title => "raw title"
      c.title.should_not be_nil
    end

    describe "#featured_channels" do
      it "returns channels which top categories are also self" do
        ch1 = mock("channel").tap do |c|
          c.stub :id => 1
          c.stub(:category_ids).and_return [subject.id]
          Channel.stub(:find_by_id).with(c.id).and_return c
        end

        ch2 = mock("channel").tap do |c|
          c.stub :id => 2
          c.stub(:category_ids).and_return [4]
          Aji::Channel.stub(:find_by_id).with(c.id).and_return c
        end

        subject.stub(:channel_ids).and_return([ch1.id, ch2.id])

        featured = subject.featured_channels
        featured.should include ch1
        featured.should_not include ch2
      end
    end
  end
end
