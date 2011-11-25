require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::Category, :unit do
    subject do
      Category.new.tap do |c|
        c.stub :id => 1
        c.stub :title => 'News'
        Category.stub(:find).with(c.id).and_return(c)
        Category.stub(:find_by_id).with(c.id).and_return(c)
        Category.stub(:find_by_title).and_return(c)
      end
    end

    it_behaves_like "any redis object model"
    it_behaves_like "any featured model"

    it "sets title as raw_title after create" do
      c = Category.create :raw_title => "raw title"
      c.title.should_not be_nil
    end

    describe "#thumbnail_uri" do
      it "returns corresponding thumbnail" do
        subject.stub title: 'Comedy'
        subject.thumbnail_uri.should ==
          "http://#{Aji.conf['TLD']}/images/icons/now#{subject.title.downcase}.png"
      end

      it "returns default thumbnail otherwise" do
        subject.stub title: random_string
        thumbnail = subject.thumbnail_uri
        thumbnail.split('/').last.should == 'nowfilm.png'
      end
    end

    describe "#serializable_hash" do
      it "contains specific keys" do
        returned = subject.serializable_hash
        ['id', 'title', 'thumbnail_uri'].each do |key|
          returned.should have_key key
        end
      end
    end

    describe "#update_channel_relevance" do
      let(:channel) { mock "channel", :id=>1 }
      it "overwrites previous relevance with new one" do
        old_relevance, new_relevance = 100, 200
        subject.update_channel_relevance channel, old_relevance
        expect { subject.update_channel_relevance channel, new_relevance }.
          to change { subject.channel_id_zset.score channel.id }.
          from(old_relevance).to(new_relevance)
      end
    end

    describe "#featured_channels" do
      let(:ch1) { mock "channel1", :available? => true,
        :category_ids => [subject.id], :youtube_channel? => true }
      let(:ch2) { mock "channel2", :available? => true,
        :category_ids => [4], :youtube_channel? => true  }

      before :each do
        subject.stub(:channels).and_return([ch1, ch2])
      end

      it "returns channels which top categories are also self" do
        featured = subject.featured_channels
        featured.should include ch1
        featured.should_not include ch2
      end

      it "skips unavailable channels" do
        ch1 = mock "unavailable channel",
          :category_ids => [subject.id], :available? => false

        subject.featured_channels.should_not include ch1
      end

      it "only features YouTube channels" do
        ch1.stub :youtube_channel? => false

        subject.featured_channels.should_not include ch1
      end

    end
  end
end
