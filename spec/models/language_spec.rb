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

      let(:id_tag_en) { "en_US"}
      let(:id_tag_zh) { "zh-hans_HK"}
      it "returns the 2 letter ISO language code" do
        en = Language.new id_tag_en
        en.iso_code.should == "en"

        zh = Language.new id_tag_zh
        zh.iso_code.should == "zh"
      end

      let(:id_tag_ace) { "ace_xxx"}
      it "returns english if locale has a 3 letter ISO code" do
        ace = Language.new id_tag_ace
        ace.iso_code.should == "en"
      end

      let(:id_tag_nil) { nil }
      it "returns english if locale is nil" do
        empty = Language.new id_tag_nil
        empty.iso_code.should == "en"
      end
    end

  end
end
