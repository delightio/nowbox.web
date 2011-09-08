shared_examples_for "any featured model" do

  before(:each) do
    subject.feature
  end

  describe "an featured model" do

    describe ".featured_ids" do
      it "is an list of featured object ids" do
        subject.class.featured_ids.should == [subject.id]
      end
    end

    describe ".featured" do
      it "returns a list of featured objects" do
        subject.class.featured.should == [subject]
      end
    end

    describe "#feature" do
      it "adds object id into featured_ids" do
        subject.unfeature
        expect { subject.feature }.
          to change { subject.class.featured_ids }.
          from([]).to([subject.id])
      end
    end

    describe "#unfeature" do
      it "remoes object id from featured_ids" do
        expect { subject.unfeature }.
          to change { subject.class.featured_ids }.
          from([subject.id]).to([])
      end
    end

    describe "#featured?" do
      it "is true for featured object" do
        subject.should be_featured
      end
    end
  end

end
