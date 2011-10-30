require File.expand_path("../../spec_helper", __FILE__)
include Aji

describe "Decay" do
  describe ".exponentially" do
    let(:time_diffs) { [100, 200, 300] }
    it "ignores NaN input" do
      current = Decay.exponentially time_diffs
      time_diffs << Float::NAN
      Decay.exponentially(time_diffs).should be_within(1.0).of(current)
    end
  end
end