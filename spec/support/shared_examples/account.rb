shared_examples_for "any account" do
  it_behaves_like "any content holder"
  it_behaves_like "any redis object model"

  describe "an account" do
    it "has an identity" do
      subject.should respond_to :identity, :identity_id
    end

    it "has many channels" do
      subject.should respond_to :channels, :channel_ids
    end

    it "has a thumbnail_uri" do
      subject.should respond_to :thumbnail_uri
    end

    it "has a description" do
      subject.should respond_to :description
    end

    it "has a username" do
      subject.should respond_to :username
    end

    it "has a realname" do
      subject.should respond_to :realname
    end

    it "has a profile_uri" do
      subject.should respond_to :profile_uri
    end

  end
end
