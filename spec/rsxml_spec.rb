require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rsxml'

describe Rsxml do
  describe "to_xml" do
    it "should produce a single-element document" do
      Rsxml.to_xml([:foo]).should == "<foo></foo>"
    end

    it "should produce a single-element doc with namespaces" do
      Rsxml.to_xml([[:bar, :foo, "http://foo.com/foo"]]).should ==
        '<foo:bar xmlns:foo="http://foo.com/foo"></foo:bar>'
    end

    it "should produce a fragment without namespace declarations if ns bindings are provided" do
      Rsxml.to_xml(["foo:bar", {["baz", "foo"]=>"bazbaz"}], :ns=>{"foo"=>"http://foo.com/foo"}).should ==
        '<foo:bar foo:baz="bazbaz"></foo:bar>'
    end

    it "should produce a single-element doc with attrs" do
      xml = Rsxml.to_xml([:foo, {:bar=>1, :baz=>"baz"}])
      r = Nokogiri::XML(xml).children.first
      r.name.should == "foo"
      r["bar"].should == "1"
      r["baz"].should == "baz"
    end

    it "should produce a single-element doc with  element namespace attrs" do
      xml = Rsxml.to_xml([[:bar, :foo, "http://foo.com/foo"], {:bar=>1, :baz=>"baz"}])
      r = Nokogiri::XML(xml).children.first
      r.name.should == "bar"
      r.namespace.href.should == "http://foo.com/foo"
      r.namespace.prefix.should == "foo"

      r.attributes["bar"].namespace.should == nil
      r["bar"].should == "1"

      r.attributes["baz"].namespace.should == nil
      r["baz"].should == "baz"
    end

    it "should produce a single-element doc with namespace and attr namespaces" do
      xml = Rsxml.to_xml([[:bar, :foo, "http://foo.com/foo"],
                          {[:barbar, :bar, "http://bar.com/bar"]=>1,
                            :baz=>"baz"}])
      r = Nokogiri::XML(xml).children.first

      r.name.should == "bar"
      r.namespace.prefix.should == "foo"
      r.namespace.href.should == "http://foo.com/foo"

      barbar = r.attributes["barbar"]
      barbar.namespace.prefix.should == "bar"
      barbar.namespace.href.should == "http://bar.com/bar"
      barbar.value.should == "1"

      baz = r.attributes["baz"]
      baz.namespace.should == nil
      baz.value.should == "baz"
    end

    it "should produce a single-element doc with default namespace and attr namespaces" do
      xml = Rsxml.to_xml([[:bar, "", "http://foo.com/foo"],
                          {[:barbar, :bar, "http://bar.com/bar"]=>1,
                            :baz=>"baz"}])
      r = Nokogiri::XML(xml).children.first

      r.name.should == "bar"
      r.namespace.prefix.should == nil
      r.namespace.href.should == "http://foo.com/foo"

      barbar = r.attributes["barbar"]
      barbar.namespace.prefix.should == "bar"
      barbar.namespace.href.should == "http://bar.com/bar"
      barbar.value.should == "1"

      baz = r.attributes["baz"]
      baz.namespace.should == nil
      baz.value.should == "baz"
    end

    it "should produce a doc with text content" do
      xml = Rsxml.to_xml([:foo, "foofoo"])
      r = Nokogiri::XML(xml).children.first
      r.name.should == "foo"
      r.children.size.should == 1
      txt = r.children.first
      txt.text?.should == true
      txt.text.should == "foofoo"
    end

    it "should produce a doc with child elements" do
      xml = Rsxml.to_xml([:foo, [:bar], [:baz]])
      r = Nokogiri::XML(xml).children.first
      r.name.should == "foo"
      r.children.length.should == 2
      bar = r.children.first
      bar.name.should == "bar"
      bar.children.length.should == 0
      baz = r.children[1]
      baz.name.should == "baz"
      baz.children.length.should == 0
    end

    it "should produce a doc with child elements and attributes" do
      xml = Rsxml.to_xml([:foo, [:bar, {:barbar=>"boo", :bazbaz=>"baz"}]])
      r = Nokogiri::XML(xml).children.first
      r.name.should == "foo"
      r.children.length.should == 1
      bar = r.children.first
      bar.name.should == "bar"
      bar.children.length.should == 0
      bar["barbar"].should == "boo"
      bar["bazbaz"].should == "baz"
    end

    it "should treat namespace prefixes reasonably" do
      xml = Rsxml.to_xml(["foo:foofoo", {"xmlns:foo"=>"http://foo.com/foo", "foo:bar"=>1, "foo:baz"=>"baz"}])

      r = Nokogiri::XML(xml).children.first
      r.namespaces["xmlns:foo"].should == "http://foo.com/foo"

      r.name.should == "foofoo"
      r.namespace.href.should == "http://foo.com/foo"
      r.namespace.prefix.should == "foo"

      r["bar"].should == "1"
      r.attributes["bar"].namespace.href.should == "http://foo.com/foo"
      r.attributes["bar"].namespace.prefix.should == "foo"

      r["baz"].should == "baz"
      r.attributes["baz"].namespace.href.should == "http://foo.com/foo"
      r.attributes["baz"].namespace.prefix.should == "foo"
    end
  end

  describe "to_rsxml" do

    def test_roundtrip(org)
      xml = Rsxml.to_xml(org)
      rsxml = Rsxml.to_rsxml(xml, :style=>:xml)
      rsxml.should == org
    end

    it "should parse a single-element doc" do
      test_roundtrip(["foo"])
    end

    it "should parse a single-element doc with attributes" do
      test_roundtrip(["foo", {"bar"=>"1", "baz"=>"bazbaz"}])
    end

    it "should parse a doc with child elements" do
      test_roundtrip(["foo", ["bar"], ["baz", ["boo"]]])
    end

    it "should parse a doc with text content" do
      test_roundtrip(["foo", "foofoo"])
    end

    it "should parse a doc with child elements and attributes" do
      test_roundtrip(["foo", {"bar"=>"1", "baz"=>"bazbaz"}, ["foofoo", {"foobar"=>"3", "barbaz"=>"4"}, "foofoofoo"]])
    end

    it "should parse a doc with namespaces" do
      test_roundtrip(["foo:foofoo", {"xmlns:foo"=>"http://foo.com/foo", "foo:bar"=>"1", "foo:baz"=>"baz"}])
    end

    it "should parse a doc with namespaces and return exploded names if :style is :exploded" do
      xml = Rsxml.to_xml(["foo:foofoo", {"xmlns:foo"=>"http://foo.com/foo", "foo:bar"=>"1", "foo:baz"=>"baz"}])
      rsxml = Rsxml.to_rsxml(xml, :style=>:exploded)
      rsxml.should == [["foofoo", "foo", "http://foo.com/foo"],
                       { ["bar", "foo", "http://foo.com/foo"]=>"1",
                         ["baz", "foo", "http://foo.com/foo"]=>"baz"}]

    end

    it "should allow namespace prefixes to be specified when parsing a fragment" do
      org_no_ns = ["foofoo", {"foo:bar"=>"1", "foo:baz"=>"baz"}]
      xml = '<foofoo foo:bar="1" foo:baz="baz"></foofoo>'

      rsxml = Rsxml.to_rsxml(xml, :ns=>{:foo=>"http://foo.com/foo", ""=>"http://baz.com/baz"}, :style=>:xml)

      rsxml.should == org_no_ns
    end

    it "should return exploded namespaces if :style=>:exploded when parsing a fragment" do
      xml = '<foofoo foo:bar="1" foo:baz="baz"></foofoo>'
      rsxml = Rsxml.to_rsxml(xml, :ns=>{:foo=>"http://foo.com/foo", ""=>"http://baz.com/baz"}, :style=>:exploded)

      rsxml.should == [["foofoo", "", "http://baz.com/baz"],
                       { ["bar", "foo", "http://foo.com/foo"]=>"1",
                         ["baz", "foo", "http://foo.com/foo"]=>"baz"}]
    end

  end

  describe "compare" do
    it "should return true when two simple docs are equivalent" do
      Rsxml.compare(["Foo"], "<Foo></Foo").should == true
    end

    it "should return true when two simple docs with attributes are equivalent" do
      Rsxml.compare([:foo, {:bar=>1, :baz=>"baz"}],
                    [:foo, {:bar=>1, :baz=>"baz"}]).should == true
    end

    it "should return true when two more complex docs are equivalent" do
      Rsxml.compare(["foo:foofoo", {"xmlns:foo"=>"http://foo.com/foo", "foo:bar"=>1, "foo:baz"=>"baz"}, ["Bar", "barbar"], ["Baz"]],
                    ["foo:foofoo", {"xmlns:foo"=>"http://foo.com/foo", "foo:bar"=>1, "foo:baz"=>"baz"}, ["Bar", "barbar"], ["Baz"]]).should ==true
    end

    it "should raise an error when two simple docs differ" do
      lambda {
        Rsxml.compare(["Foo"], "<Boo></Boo").should == true
      }.should raise_error("[]: element names differ: 'Foo', 'Boo'")
    end

    it "should raise an error when two more complex docs differ" do
      lambda {
        Rsxml.compare(["foo:foofoo", {"xmlns:foo"=>"http://foo.com/foo", "foo:bar"=>1, "foo:baz"=>"baz"}, ["Bar", "barbAr"], ["Baz"]],
                      ["foo:foofoo", {"xmlns:foo"=>"http://foo.com/foo", "foo:bar"=>1, "foo:baz"=>"baz"}, ["Bar", "barbar"], ["Baz"]]).should ==true
      }.should raise_error("[foo:foofoo/Bar]: content differs: 'barbAr', 'barbar'")

    end
  end
end
