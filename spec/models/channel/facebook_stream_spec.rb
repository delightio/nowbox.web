require File.expand_path("../../../spec_helper", __FILE__)

module Aji
  describe Channel::FacebookStream do
    subject { Channel::FacebookStream.create }
    it_behaves_like "any channel"
  end
end
