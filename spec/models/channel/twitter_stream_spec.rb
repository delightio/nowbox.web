require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Aji::Channel::TwitterStream, :unit do
    let(:video) do
      mock("video").tap do |v|
        v.stub :id => 7
        def v.populate
          yield self
        end
      end
    end

    let(:api) do
      mock "api", :video_mentions_in_feed => [
        stub(:published_at => Time.now,
         :videos => [video])
      ]
    end

  subject do
    Channel::TwitterStream.new.tap do |c|
      c.stub :owner => stub(:api => api)
      c.stub :id => 1
    end
  end

  it_behaves_like "any channel"

  end
end

