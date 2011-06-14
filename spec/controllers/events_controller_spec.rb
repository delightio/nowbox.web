require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "events"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      
      describe "post #{resource}/" do
        it "should create event object on post with default channel listing" do
          user = Factory :user
          channel = Factory :channel_with_videos
          video = channel.content_videos.sample
          event_type = Aji::Supported.event_types.sample
          user.viewed_videos.should_not include video
          params = { :user_id=>user.id, :video_id=>video.id, :channel_id=>channel.id, :video_elapsed=>rand(10), :event_type=>event_type}
          post "#{resource_uri}/", params
          last_response.status.should ==201
          user.viewed_videos.should include video
        end
        it "should return 400 if missing parameters"
          user = Factory :user
          channel = Factory :channel_with_videos
          event_type = Aji::Supported.event_types.sample
          params = { :user_id=>user.id, :channel_id=>channel.id, :video_elapsed=>rand(10), :event_type=>event_type }
          post "#{resource_uri}/", params
          last_response.status.should == 400
      end
      
    end
  end
end