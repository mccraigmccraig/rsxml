require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Rsxml do
  describe "to_xml" do
    it "should produce a single-element document" do
      Rsxml.to_xml([:foo]).should == "<foo></foo>"
    end

    it "should produce a single-element doc with attrs" do
      xml = Rsxml.to_xml([:foo, {:bar=>1, :baz=>"baz"}])
      r = Nokogiri::XML(xml).children.first
      r.name.should == "foo"
      r["bar"].should == "1"
      r["baz"].should == "baz"
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
      rsxml = Rsxml.to_rsxml(xml)
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
  end
end