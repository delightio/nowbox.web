shared_examples_for "any featured model" do
  describe "an featured model" do

    it "has an list of featured object ids" do
puts "subject.class: #{subject.class}"
      subject.class.send(:featured_ids).should be an_instance_of(Array)
    end

    it "can be featured" do
      expect { subject.feature }.
        to change { subject.featured? }.to(true)
    end
  end

  describe ".featured" do
    before(:each) do
      subject.feature
    end

    it "returns list of featured objects" do
      subject.class.featured.should == [subject]
    end
  end

end
