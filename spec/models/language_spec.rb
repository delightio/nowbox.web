# require File.expand_path("../../spec_helper", __FILE__)
require File.expand_path("../../../models/language", __FILE__)

module Aji
  describe Aji::Language do
    subject { Language.new nil }

    describe "#default_iso_code" do
      it "is en" do
        subject.default_iso_code.should == "en"
      end
    end

    describe "#iso_code" do

      let(:locale_en) { "en_US"}
      let(:locale_zh) { "zh-hans_HK"}
      it "returns the 2 letter ISO language code" do
        en = Language.new locale_en
        en.iso_code.should == "en"

        zh = Language.new locale_zh
        zh.iso_code.should == "zh"
      end

      let(:locale_ace) { "ace_xxx"}
      it "returns english if locale has a 3 letter ISO code" do
        ace = Language.new locale_ace
        ace.iso_code.should == "en"
      end

      let(:locale_nil) { nil }
      it "returns english if locale is nil" do
        empty = Language.new locale_nil
        empty.iso_code.should == "en"
      end
    end

  end
end
