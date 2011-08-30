shared_examples_for "any account" do
  it_behaves_like "any content holder"

  it "has an identity" do
    subject.respond_to :identity
  end

  it "has many channels" do
    subject.respond_to :channels, :channel_ids
  end

end
