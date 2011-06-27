require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "videos"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      describe "get #{resource_uri}/:id" do
        it "should return 404 if not found" do
          get "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 404
        end
        
        it "should return video info if found"
      end
      
      describe "put #{resource_uri}/:id" do
        it "should never return given video id again" do
          channel = Factory :channel_with_videos
          user = Factory :user
          bad_video = channel.content_videos.sample
          channel.personalized_content_videos(:user=>user,:limit=>channel.content_videos.count).should include bad_video
          Aji::Queues::ExamineVideo.perform bad_video.id # TODO/HACK: how do rspec w/ resque queue?
          channel.personalized_content_videos(:user=>user,:limit=>channel.content_videos.count).should_not include bad_video
        end
        
        it "should queue the given video id in examine video queue" do
          params = {:video_action => "examine"}
          put "#{resource_uri}/#{rand(100)}", params
            Resque.size(:examine_video).should == 1
        end
        
        it "should return 400 if invalid action" do
          put "#{resource_uri}/#{rand(100)}"
          last_response.status.should == 400
        end
      end
    end
  end
end