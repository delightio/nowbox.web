require File.expand_path("../../../spec_helper", __FILE__)

describe Aji::Mixins::Formatters do
  let(:long_message) { "A really #{"long" * 15} string" }
  let(:short_message) { "Hah this video!" }
  let(:link_text) { "http://nowbox.com/shares/51232" }
  let(:coda) { " #{link_text} via @nowbox for iPad" }

  describe Aji::Mixins::Formatters::Twitter do
    subject { Class.new { include Aji::Mixins::Formatters::Twitter }.new }
    let(:long_share) { stub :message => long_message, :link => link_text }
    let(:short_share) { stub :message => short_message, :link => link_text }

    it "shortens messages to less than 140 characters" do
      subject.format(long_share).length.should be < 140
      subject.format(short_share).length.should be < 140
    end

    it "includes the link text no matter the message length" do
      subject.format(long_share).should include link_text
      subject.format(short_share).should include link_text
    end

    it "includes the twitter coda" do
      subject.format(long_share).should include coda
      subject.format(short_share).should include coda
    end
  end

  describe Aji::Mixins::Formatters::Facebook do
    subject { Class.new { include Aji::Mixins::Formatters::Facebook }.new }

    let(:video)   { stub :title => stub, :thumbnail_uri => stub }
    let(:channel) { stub :title => stub }
    let(:share)   { stub :message => "A message",
                        :link => "http://link.io",
                        :video => video,
                        :channel => channel }

    it "returns a message" do
      message, attachment = *subject.format(share)
      message.should be_present
    end

    it "returns an attachment hash with specific keys" do
      message, attachment = *subject.format(share)
      ["name", "link", "caption", "description", "picture"].each do |required_key|
        attachment.should have_key(required_key)
      end
    end

  end
end

