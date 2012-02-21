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

      header 'X-NB-AuthToken', Token::Generator.new(@user).token
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
        post "#{resource_uri}", :user_id => @user.id
        last_response.status.should == 400
      end

      it "creates event objects from video external id" do
        Event.send(:video_actions).each do |action|
          params = { :user_id => @user.id,
                     :video_elapsed => rand(10),
                     :action => action,
                     :channel_id => @channel.id,
                     :video_source => @video.source,
                     :video_uid => @video.external_id }
          expect { post("#{resource_uri}/", params) }.
            to change { Event.count }.by(1)
          last_response.status.should == 201
        end
      end

      it "creates event objects from channel uid" do
        Event.send(:channel_actions).each do |action|
          params = { :user_id => @user.id,
                     :action => action,
                     :channel_uid => '501776555',
                     :channel_source => 'facebook' }
          expect { post("#{resource_uri}/", params) }.
            to change { Event.count }.by(1)
          last_response.status.should == 201
        end
      end

    end
  end
end

