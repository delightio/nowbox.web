require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Aji::Channel::Keyword do
    let(:api) { mock :api, :keyword_search => [stub(:id => 1)] }

    subject do
      Channel::Keyword.create(keywords: %w[ ukulele ]).tap do |c|
        c.stub :api => api
      end
    end

    it_behaves_like "any channel"

    describe "#search_helper" do
      let(:count) { 3 }
      let(:query) { Array.new(count){ |n| random_string }.join(",") }

      it "does not create new channel" do
        expect{ Aji::Channel::Keyword.search_helper query }.to_not(
          change{ Aji::Channel.count })
      end

      it "returns a match even if partial match is shorter" do
        q = query.split(',').shuffle.sample(count-1)
        old_keyword_channel = Aji::Channel::Keyword.create(
          :keywords => q)
          results = Aji::Channel::Keyword.search_helper query
          results.should have(1).channel
          results.should include old_keyword_channel
      end

      it "returns a match even if partial match is longer" do
        q = query.split(',').shuffle << random_string
        old_keyword_channel = Aji::Channel::Keyword.create(
          :keywords => q)
          results = Aji::Channel::Keyword.search_helper query
          results.should have(1).channel
          results.should include old_keyword_channel
      end

      it "returns existing keyword channel regardless of query order" do
        old_keyword_channel = Aji::Channel::Keyword.create(
          :keywords => query.split(',').shuffle)
          results = Aji::Channel::Keyword.search_helper query
          results.should have(1).channel
          results.should include old_keyword_channel
      end
    end

    describe "#sort_keywords" do
      let(:sorted_keywords) { %w[ a b c d e f ] }
      subject { Aji::Channel::Keyword.new keywords: sorted_keywords.shuffle }

      it "sorts keywords" do
        subject.sort_keywords

        subject.keywords == sorted_keywords
      end
    end

  end
end
