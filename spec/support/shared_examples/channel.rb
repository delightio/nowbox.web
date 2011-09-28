shared_examples_for "any channel" do
  it_behaves_like "any content holder"

  it "has a thumbnail_uri" do
    subject.should respond_to :thumbnail_uri
  end

  describe "#background_refresh_content" do
    it "enques a refresh job" do
      Resque.should_receive(:enqueue).with(
        Aji::Queues::RefreshChannel, subject.id).at_most(2).times
      subject.background_refresh_content
    end
  end
end
