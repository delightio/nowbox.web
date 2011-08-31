shared_examples_for "any channel" do
  it_behaves_like "any content holder"

  it "has a thumbnail_uri" do
    subject.should respond_to :thumbnail_uri
  end

  it "has many categories" do
    subject.should respond_to :category_ids, :categories
  end

end
