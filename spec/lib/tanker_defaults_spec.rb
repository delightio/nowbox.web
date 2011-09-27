require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe TankerDefaults do
    subject { Account.new }
    before :each do
      Searcher.stub(:enabled?).and_return(true)
    end

    describe "#searchable?" do
      it "is false if we don't have any content" do
        subject.stub(:content_video_id_count).and_return(0)
        subject.should_not be_searchable
      end

      it "is true if we have reached minimal number of content videos" do
        subject.stub(:content_video_id_count).and_return(
          Searcher.minimun_video_count+1)
        subject.should be_searchable
      end
    end

    describe "#update_tank_indexes_if_searchable" do
      it "is no op if not searchable" do
        subject.stub(:searchable?).and_return(false)
        subject.should_receive(:update_tank_indexes).never
        subject.save
      end

      it "updates self on index tank" do
        subject.stub(:searchable?).and_return(true)
        subject.should_receive(:update_tank_indexes).once
        subject.save
      end
    end

    describe "#delete_tank_indexes_if_searchable" do
      it "is no op if not searchable" do
        subject.stub(:searchable?).and_return(false)
        subject.should_receive(:delete_tank_indexes).never
        subject.save
      end

      it "delete self form index tank" do
        subject.stub(:searchable?).and_return(true)
        subject.should_receive(:delete_tank_indexes).once
        subject.save
      end
    end

  end
end