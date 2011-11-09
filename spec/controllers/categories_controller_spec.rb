require File.expand_path("../../spec_helper", __FILE__)

include Aji
resource = "categories"
resource_uri = "/#{API.version.first}/#{resource}"

describe API do
  describe "resource: #{resource}" do
    subject { Category.create :raw_title => "superhero" }
    let(:user) { Factory :user }
    before { header 'X-NB-AuthToken', Token::Generator.new(user).token }

    describe "get #{resource_uri}/:id" do
      it "returns given category resource" do # TODO
        get "#{resource_uri}/#{subject.id}"
        last_response.status.should == 200
      end
    end

    describe "get #{resource_uri}/" do

      before { 3.times { Factory(:category).feature } }

      it "fails if missing type or user_id" do
        get resource_uri
        last_response.status.should == 400
      end

      it "returns all featured categories when ?type=featured&user_id=UID are given" do
        params = { :user_id => user.id, :type => "featured" }
        get "#{resource_uri}", params
        last_response.status.should == 200
        body_hash = JSON.parse last_response.body
        returned_categories = body_hash.map {|h| h["category"]}
        returned_categories.map{ |h| h["id"] }.
          should == Aji::Category.featured_ids
      end

      it "does not return undefined category" do
        params = { :user_id => user.id, :type => "featured" }
        get "#{resource_uri}", params
        last_response.status.should == 200
        body_hash = JSON.parse last_response.body
        returned_categories = body_hash.map {|h| h["category"]}
        returned_categories.should_not include Category.undefined
      end

      it "returns featured categories" do
        Category.should_receive(:featured).and_return([subject])
        params = { :user_id => user.id, :type => "featured" }
        get "#{resource_uri}", params
      end
    end

    describe "get #{resource_uri}/:id/channels" do
      it "fails if missing user_id" do
        get "#{resource_uri}/#{rand(10)}/channels"
        last_response.status.should == 401
      end

      it "returns all featured channels when ?type=featured&user_id=UID are given" do
        channel = Factory :youtube_channel
        params = { :user_id => user.id, :type => "featured" }
        subject.should_receive(:featured_channels).and_return([channel])
        Category.stub(:find_by_id).with(subject.id.to_s).and_return(subject)
        get "#{resource_uri}/#{subject.id}/channels", params
        last_response.status.should == 200
        returned_channels = JSON.parse last_response.body
        returned_channels = returned_channels.map {|h| h["account"]}
        returned_channels.should include channel.serializable_hash
      end
    end
  end
end
