require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "channels"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do

      describe "get #{resource_uri}/:id" do
        it "returns 404 if not found" do
          cid = rand(100)
          Channel.find_by_id(cid).should be_nil
          get "#{resource_uri}/#{cid}"
          last_response.status.should == 404
        end

        it 'returns channel object if found' do
          c = Factory :youtube_channel_with_videos
          get "#{resource_uri}/#{c.id}"
          last_response.status.should == 200
        end
      end

      describe "get #{resource_uri}" do
        it "always create keyword channel based on query" do
          pending "need Channel::Keyword.search_helper"
          query = random_string
          params = { :query => query, :user_id => (Factory :user).id }
          expect { get "#{resource_uri}", params }.to change { Channel.count }.by(1)
        end

        it "searches existing channels and returns matched channels"

        it "returns all channels if no user id given" do
          total = 10
          total.times {|n| Factory :youtube_channel_with_videos }
          get "#{resource_uri}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map {|h| h["youtube_account"]}
          returned_channels.should have(total).channels
        end

        it "returns subscribed channels if given user id" do
          user = Factory :user
          channel = Factory :youtube_channel_with_videos
          user.subscribe channel
          params = { :user_id => user.id }
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map {|h| h["youtube_account"]}
          returned_channels.should include channel.serializable_hash
        end

        it "retures min number of results if debug mode is turned on" do
          min_count = 10
          (min_count*2).times {|n| Factory :youtube_channel_with_videos }
          params = { :query => random_string, :debug_min_count => min_count }
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map {|h| h["youtube_account"]}
          returned_channels.should have(min_count).channels
        end

        it "returns error if debug_min_count is not a number" do
          params = { :query => random_string, :debug_min_count => random_string }
          get "#{resource_uri}", params
          last_response.status.should_not == 200
        end
      end

      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end

        it "should show channel info if found" do
          channel = Factory :youtube_channel_with_videos
          get "#{resource_uri}/#{channel.id}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == channel.serializable_hash
        end
      end

      describe "get #{resource_uri}/:id/videos" do
        it "requires a user_id" do
          channel = Factory :youtube_channel_with_videos
          get "#{resource_uri}/#{channel.id}/videos", {}
          last_response.status.should == 404
        end

        it "respects limit params" do
          limit = 3
          channel = Factory :youtube_channel_with_videos
          channel.content_videos.count.should > limit
          params = {:user_id=>(Factory :user).id, :limit=>3}
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.count.should == limit
        end

        it "should not returned viewed videos" do
          channel = Factory :youtube_channel_with_videos
          viewed_video = channel.content_videos.sample
          user = Factory :user
          event = Factory :event, :event_type => :view, :user => user, :video => viewed_video
          params = {:user_id => user.id }
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          video_ids = body_hash.map {|h| h["video"]["id"]}
          video_ids.should_not include viewed_video.id
        end
      end

    end
  end
end
