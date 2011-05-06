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

    it "should transform a single tag if a transformer is supplied" do
      xml = Rsxml.to_xml([:foo]) do |tag,attrs,path| 
        path.should == ""
        [tag.upcase, attrs]
      end.should ==
        "<FOO></FOO>"
    end

    it "should transform nested tags if a transformer is supplied" do
      txs = {"/foo"=>"Blub", "/foo[0]/bar"=>"Wub"}
      xml = Rsxml.to_xml([:foo, [:bar]]) do |tag,attrs,path| 
        $stderr << [tag, attrs, path].inspect
        attrs.should == {}
        [txs[[path, tag].join("/")], attrs]
      end.should ==
        "<Blub><Wub></Wub></Blub>"
    end

    it "should transform a tag with attributes if a transformer is supplied" do
      xml = Rsxml.to_xml([:foo, {:bar=>"bar"}]) do |tag,attrs,path| 
        path.should == ""
        [tag.upcase, Hash[*attrs.map{|k,v| [k.to_s.upcase,v]}.flatten]]
      end.should ==
        '<FOO BAR="bar"></FOO>'
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

    it "should allow namespace prefixes to be specified when parsing a fragment" do
      org = ["foo:foofoo", {"foo:bar"=>"1", "foo:baz"=>"baz"}]
      xml = Rsxml.to_xml(["foo:foofoo", {"foo:bar"=>"1", "foo:baz"=>"baz"}])

      org_with_ns = ["foo:foofoo", {"foo:bar"=>"1", "foo:baz"=>"baz", "xmlns"=>"http://baz.com/baz", "xmlns:foo"=>"http://foo.com/foo"}]
      rsxml = Rsxml.to_rsxml(xml, :ns=>{:foo=>"http://foo.com/foo", ""=>"http://baz.com/baz"})

      rsxml.should == org_with_ns
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
