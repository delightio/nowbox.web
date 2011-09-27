require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Account::Facebook, :unit do
    let(:video) do
      mock("video").tap do |v|
        v.stub :id => 7

        def v.populate
          yield self
        end
      end
    end

    let(:api) do
      mock "api", :video_mentions_i_post => [
        stub(:published_at => Time.now,
         :videos => [video]) ]
    end

    subject do
      Account::Facebook.create(:uid => "501776555", :credentials => { 'token' =>
        "AAACF78hfSZBEBAM0leS4CSzXZARd7S68Al6uVzs8DwJ8huZAm1YsjYeiZA2gBR3p7Ue8l3EPrKjkv6EtmOQuXo95aNTIcPIZD"
      }).tap do |a|
        a.stub :api => api
      end

    end

    it_behaves_like "any account"
  end
end


