require File.expand_path("../../spec_helper", __FILE__)

module Aji
  describe Aji::VideoAPI do
    describe ".source_apis" do
      it "uses symbols to point to classes" do
        VideoAPI.source_apis.each do |symbol, api_class|
          symbol.should be_kind_of(Symbol)
          api_class.should be_kind_of(Class)
        end
      end
    end

    describe "#method_missing" do
      it "delegates to specified sources" do
        VideoAPI.source_apis.values.each do |source|
          source.any_instance.should_receive(:method_name).with(:arg1, :arg2)
        end

        subject.method_name :arg1, :arg2
      end

      it "returns an array containing the results from each source" do
        VideoAPI.source_apis.values.each do |source|
          source.any_instance.should_receive(:meth).with(:arg1).and_return(
          :return_value)
        end

        subject.meth(:arg1).should == Array.new(VideoAPI.source_apis.count,
          :return_value)
      end

    end
  end
end
