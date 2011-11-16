require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::Formatters do
  let(:long_message) { "A really #{"long" * 15} string" }
  let(:short_message) { "Hah this video!" }
  let(:link_text) { "http://nowbox.com/shares/51232" }
  let(:coda) { " #{link_text} via @nowbox for iPad" }

  describe Aji::Mixins::Formatters::Twitter do
    subject { Class.new { include Aji::Mixins::Formatters::Twitter }.new }

    it "shortens messages to less than 140 characters" do
      subject.format(long_message, link_text).length.should be < 140
      subject.format(short_message, link_text).length.should be < 140
    end

    it "includes the link text no matter the message length" do
      subject.format(long_message, link_text).should include link_text
      subject.format(short_message, link_text).should include link_text
    end

    it "includes the twitter coda" do
      subject.format(long_message, link_text).should include coda
      subject.format(short_message, link_text).should include coda
    end
  end

  describe Aji::Mixins::Formatters::Facebook do
    subject { Class.new { include Aji::Mixins::Formatters::Facebook }.new }

    it "includes the link text no matter the message length" do
      subject.format(long_message, link_text).should include link_text
      subject.format(short_message, link_text).should include link_text
    end

    it "includes the facebook coda" do
      subject.format(long_message, link_text).should include coda
      subject.format(short_message, link_text).should include coda
    end
  end
end

