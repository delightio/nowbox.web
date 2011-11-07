require File.expand_path("../../spec_helper", __FILE__)

resource = "shares"
resource_uri = "/#{Aji::API.version.first}/#{resource}"

include Aji

describe Aji::API do
  describe "resource: #{resource}" do

    let(:twitter_account) { stub.as_null_object }
    let(:user) { Factory :user }
    let(:channel) { Factory :channel }
    let(:video) { Factory :video }
    let(:network) { "twitter" }
    let(:params) {{:user_id => user.id,
                   :channel_id => channel.id,
                   :video_id => video.id,
                   :network => network} }

    # TODO: I couldn't get user.twitter_acccount to return the stub
    # So I had to do it this way.
    before(:each) do
      Share.any_instance.stub(:publisher).and_return(twitter_account)
    end

    describe "POST #{resource_uri}/" do

      it "creates an event object" do
        expect { post("#{resource_uri}/", params) }.
          to change { Event.count }.by(1)
        last_response.status.should == 201
      end

      it "creates a share object" do
        expect { post("#{resource_uri}/", params) }.
          to change { Share.count }.by(1)
        last_response.status.should == 201
      end

      it "returns 404 if missing parameters" do
        post "#{resource_uri}/"
        last_response.status.should == 404
      end

      it "only supports twitter and facebook" do
        params[:network] = "youtube"
        post("#{resource_uri}/", params)
        last_response.status.should == 500
      end

    end
  end
end

