require File.expand_path("../../spec_helper", __FILE__)

module Aji
  resource = "channels"
  resource_uri = "/#{API.version.first}/#{resource}"

  describe API do
    describe "resource: #{resource}" do
      let(:user) { Factory :user }
      before { header 'X-NB-AuthToken', Token::Generator.new(user).token }

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
        it "searches existing channels and returns matched channels"

        it "returns all channels if no user id given" do
          total = 10
          total.times { Factory :youtube_channel_with_videos }
          get "#{resource_uri}"
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map{|h| h['account']}.compact
          returned_channels.should have(total).channels
        end

        it "returns user channels if given user id" do
          params = { :user_id => user.id }
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          returned_channels = body_hash.map{|h| h["user"]}.compact
          returned_channels.should have(user.displayable_user_channels.count).
            channels
          user.displayable_user_channels.each do | channel |
            returned_channels.should include channel.serializable_hash
          end
        end

        it "throws error if category_ids is present but not type" do
          params = { :category_ids => "1,2,3" }
          get "#{resource_uri}", params
          last_response.status.should == 400
        end

        let(:channel1) { Factory :youtube_channel_with_populated_videos }
        let(:channel2) { Factory :youtube_channel_with_populated_videos }
        let(:channels) { [channel1, channel2] }
        let(:categories) { channels.map {|ch| ch.content_videos(1).first.category} }
        it "returns top 2 featured channels of given categories" do
          category_ids = categories.map &:id
          params = { :category_ids => category_ids.join(','),
            :type => "featured"}
          get "#{resource_uri}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body

          returned_channels = body_hash.map{|h| h['account']}.compact
          returned_channels.should have(channels.count).channels
          returned_channels.should == [channel1.serializable_hash,
            channel2.serializable_hash]
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

        it "respects inline_videos parameter" do
          channel = Factory :youtube_channel_with_videos
          params = { :inline_videos => 3 }
          get "#{resource_uri}/#{channel.id}", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.should == channel.serializable_hash(params)
        end

      end

      describe "get #{resource_uri}/:id/videos" do
        it "requires a user_id" do
          channel = Factory :youtube_channel_with_videos
          get "#{resource_uri}/#{channel.id}/videos", {}
          last_response.status.should == 401
        end

        it "respects limit params" do
          limit = 3
          channel = Factory :youtube_channel
          channel.content_videos.count.should be > limit
          params = { :user_id => user.id, :limit => 3 }
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          body_hash.count.should == limit
        end

        it "does paging and returns new videos" do
          channel = Factory :youtube_channel_with_videos
          n = channel.content_video_ids.count
          params = { :user_id => user.id, :limit => n/2 }
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          first_page = JSON.parse last_response.body
          first_page.should have(params[:limit]).videos

          params.merge!(:page=>2)
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          second_page = JSON.parse last_response.body
          second_page.should have(params[:limit]).videos

          (first_page & second_page).should be_empty
        end

        it "returns empty array when asked for more than given channel has" do
          channel = Factory :youtube_channel_with_videos
          n = channel.content_video_ids.count
          params = { :user_id => user.id, :limit => n, :page => 10 }
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          results = JSON.parse last_response.body
          results.should be_empty
        end

        it "should not returned viewed videos" do
          channel = Factory :youtube_channel_with_videos
          viewed_video = channel.content_videos.sample
          event = Factory :event, :action => :view, :user => user, :video => viewed_video
          params = {:user_id => user.id }
          get "#{resource_uri}/#{channel.id}/videos", params
          last_response.status.should == 200
          body_hash = JSON.parse last_response.body
          video_ids = body_hash.map {|h| h["video"]["id"]}
          video_ids.should_not include viewed_video.id
        end
      end

      describe "post #{resource_uri}" do
        before(:each) do
          @query = Array.new(3){ random_string }.join(",")
          @params = { :query => @query }
        end
        it "raises error when type != keyword" do
          post "#{resource_uri}", :query => @query
          last_response.status.should_not == 201
        end
        it "raises error when missing query" do
          post "#{resource_uri}", :type => 'keyword'
          last_response.status.should_not == 201
        end
        it "creates keyword channel based on query" do
          post "#{resource_uri}", @params.merge(:type => 'keyword')
          last_response.status.should == 201
          new_channel = JSON.parse last_response.body
        end
        it "returns existing channel if found" do
          post "#{resource_uri}", @params.merge(:type => 'keyword')
          last_response.status.should == 201
          new_channel = JSON.parse last_response.body

          # Re do the search
          post "#{resource_uri}", @params.merge(:type => 'keyword')
          last_response.status.should == 201
          old_channel = JSON.parse last_response.body
          old_channel.should == new_channel
        end
      end

    end
  end
end
