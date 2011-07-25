require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "events"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do

      describe "post #{resource}/" do
        it "should create event object on post" do
          user = Factory :user
          channel = Factory :youtube_channel_with_videos
          video = channel.content_videos.sample
          event_type = Aji::Supported.event_types.delete_if{|t| t==:enqueue||t==:dequeue}.sample
          user.viewed_videos.should_not include video
          params = { :user_id=>user.id, :channel_id=>channel.id,
            :video_id=>video.id, :video_start=>video.duration/10, :video_elapsed=>video.duration/5,
            :event_type=>event_type}
          post "#{resource_uri}/", params
          last_response.status.should ==201
          user.viewed_videos.should include video
        end

        it "should return 400 if missing parameters" do
          user = Factory :user
          channel = Factory :youtube_channel_with_videos
          event_type = Aji::Supported.event_types.sample
          params = { :user_id=>user.id, :channel_id=>channel.id, :video_elapsed=>rand(10), :event_type=>event_type }
          post "#{resource_uri}/", params
          last_response.status.should == 400
        end

        it "should never return given video id again" do
          channel = Factory :youtube_channel_with_videos
          user = Factory :user
          bad_video = channel.content_videos.sample
          channel.personalized_content_videos(:user=>user,:limit=>channel.content_videos.count).should include bad_video
          Aji::Queues::ExamineVideo.perform bad_video.id # TODO/HACK: how do rspec w/ resque queue?
          channel.personalized_content_videos(:user=>user,:limit=>channel.content_videos.count).should_not include bad_video
        end

        it "should queue the given video id in examine video queue" do
          user = Factory :user
          channel = Factory :youtube_channel_with_videos
          video = channel.content_videos.sample
          params = { :user_id=>user.id, :video_id=>video.id, :channel_id=>channel.id, :video_elapsed=>rand(10), :event_type=>'examine'}
          post "#{resource_uri}/", params
          Resque.size(:examine_video).should == 1
        end
      end
    end
  end
end
