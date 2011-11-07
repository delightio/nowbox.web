require File.expand_path("../../spec_helper", __FILE__)

resource = "events"
resource_uri = "/#{Aji::API.version.first}/#{resource}"

include Aji

describe Aji::API do
  describe "resource: #{resource}" do

    before(:each) do
      @user = Factory :user
      @channel = Factory :youtube_channel_with_videos
      @video = @channel.content_videos.sample
    end

    describe "POST #{resource_uri}/" do
      it "creates event object" do
        [:video_actions, :channel_actions].each do |actions|
          params = { :user_id => @user.id, :channel_id => @channel.id }
          if actions == :video_actions
            params.merge!(:video_id => @video.id,
                          :video_start => 0, :video_elapsed=>rand(10))
          end
          Event.send(actions).each do |action|
            params.merge! :action => action
            expect { post("#{resource_uri}/", params) }.to(
              change { Event.count }.by(1))
              last_response.status.should == 201
          end
        end
      end

      it "returns 400 if missing parameters" do
        post "#{resource_uri}/"
        last_response.status.should == 400
      end

    end
  end
end

