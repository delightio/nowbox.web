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

      describe "sharing" do
        before do
          header 'X-NB-AuthToken', Token::Generator.new(bob).token
        end

        let(:bob) { Factory :user }
        let(:video) { Factory :video }
        let(:channel) { Factory :channel }
        let(:message) { "ZOMG I LOVE THIS VIDEO!!!One" }

        it "takes a message parameter and makes it the reason" do
          post "#{resource_uri}", :user_id => bob.id, :channel_id => channel.id,
            :video_id => video.id, :message => message,
            :action => :share

          Event.find(MultiJson.decode(last_response.body)['id']).reason.
            should == message

          Share.last.message.should == message
        end
      end
    end
  end
end

