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

      it "does not add self to featured_ids if self is already added" do
        subject.unfeature
        subject.should_receive(:featured?).and_return(true)
        expect { subject.feature }.
          to_not change { subject.class.featured_ids }
      end
    end

    describe "#unfeature" do
      it "removes object id from featured_ids" do
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
