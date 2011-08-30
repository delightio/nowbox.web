shared_examples_for "any account" do
  it_behaves_like "any content holder"

  it "has an identity" do
    subject.should respond_to :identity
  end

  it "has many channels" do
    subject.should respond_to :channels, :channel_ids
  end

  # should have overwritten the followings
  it "defines #profile_uri" do
    expect { subject.profile_uri }.to_not raise_error
  end
  it "defines #thumbnail_uri" do
    expect { subject.thumbnail_uri }.to_not raise_error
  end
  it "defines #description" do
    expect { subject.description }.to_not raise_error
  end

end
