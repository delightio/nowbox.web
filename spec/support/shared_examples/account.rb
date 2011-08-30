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
  end
end
