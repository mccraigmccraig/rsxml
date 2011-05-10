require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Rsxml do
  describe "to_xml" do
    it "should produce a single-element document" do
      Rsxml.to_xml([:foo]).should == "<foo></foo>"
    end

    it "should produce a single-element doc with namespaces" do
      Rsxml.to_xml([[:bar, :foo, "http://foo.com/foo"]]).should == 
        '<foo:bar xmlns:foo="http://foo.com/foo"></foo:bar>'
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

    describe "find_namespace" do
      it "should find a namespace uri in a stack of prefix bindings" do
        Rsxml::Sexp.find_namespace([{"foo"=>"http://foo.com/foo"},
                                    {"bar"=>"http://bar.com/bar"}],
                                   "bar").should == "http://bar.com/bar"
        Rsxml::Sexp.find_namespace([{"foo"=>"http://foo.com/foo"},
                                    {"bar"=>"http://bar.com/bar"}],
                                   "foo").should == "http://foo.com/foo"
      end

      it "should return nil if there is no matching binding" do
        Rsxml::Sexp.find_namespace([{"foo"=>"http://foo.com/foo"},
                                    {"bar"=>"http://bar.com/bar"}],
                                   "blah").should == nil
        Rsxml::Sexp.find_namespace([],
                                   "blah").should == nil
      end

      
    end

    describe "unqualify_name" do
      it "should do nothing to an array with more than one element" do
        Rsxml::Sexp.unqualify_name([], ["bar", "foo", "http://foo.com/foo"]).should ==
          ["bar", "foo", "http://foo.com/foo"]
        Rsxml::Sexp.unqualify_name([], ["bar", "foo"]).should ==
          ["bar", "foo"]
      end

      it "should return the first element of an array with only the first non-nil element" do
        Rsxml::Sexp.unqualify_name([], ["bar"]).should ==
          "bar"
      end

      it "should raise an error if prefix is nil but uri is not" do
        lambda {
          Rsxml::Sexp.unqualify_name([], ["bar", nil, "http://foo.com/foo"])
        }.should raise_error(/invalid name/)
      end

      it "should unqualify an unprefixed name with no default namespace" do
        Rsxml::Sexp.unqualify_name([], "bar").should == "bar"
      end

      it "should unqualify an unprefixed name in the default namespace" do
        Rsxml::Sexp.unqualify_name([{""=>"http://foo.com/foo"}], "bar").should == 
          ["bar", "", "http://foo.com/foo"]
      end

      it "should unqualify a prefixed name with a bound namespace" do
        Rsxml::Sexp.unqualify_name([{"foo"=>"http://foo.com/foo"}], "foo:bar").should ==
          ["bar", "foo", "http://foo.com/foo"]
      end

      it "should raise an error with a prefixed name with no bound namespace" do
        lambda {
          Rsxml::Sexp.unqualify_name([], "foo:bar")
        }.should raise_error(/not bound/)
      end
    end

    describe "split_qname" do
      it "should split a name with prefix" do
        Rsxml::Sexp.split_qname("foo:bar").should == ["bar", "foo"]
      end

      it "should leave a name without prefix unchanged" do
        Rsxml::Sexp.split_qname("bar").should == "bar"
      end

      it "should leave an array unchanged" do
        Rsxml::Sexp.split_qname(["bar", "foo"]).should == ["bar", "foo"]
      end
    end

    describe "qualify_attrs" do
      it "should qualify attribute names when there is a default namespaces" do
        Rsxml::Sexp.qualify_attrs([{""=>"http://default.com/default","foo"=>"http://foo.com/foo"}], {["bar", "foo"] => "barbar", ["boo", ""] => "booboo", "baz" =>"bazbaz"}).should ==
          {"foo:bar"=>"barbar", "boo"=>"booboo", "baz"=>"bazbaz"}
      end

      it "should raise an exception if a namespace is referenced but not bound" do
        lambda {
          Rsxml::Sexp.qualify_attrs([], {["bar", "foo"] => "barbar", "baz" =>"bazbaz"})
        }.should raise_error(/not bound/)
      end

      it "should raise an exception if default namespace referenced but not bound" do
        lambda {
          Rsxml::Sexp.qualify_attrs([{"foo"=>"http://foo.com/foo"}], {["bar", "foo"] => "barbar", ["boo", ""] => "booboo", "baz" =>"bazbaz"})
        }.should raise_error(/not bound/)
      end
    end

    describe "unqualify_attrs" do
      it "should unqualify attributes when there is no default namespace" do
        Rsxml::Sexp.unqualify_attrs([{"foo"=>"http://foo.com/foo"}], {"foo:bar"=>"barbar", "baz"=>"bazbaz"}).should ==
          {["bar", "foo", "http://foo.com/foo"]=>"barbar", "baz"=>"bazbaz"}
      end

      it "should unqualify attributes when there is a default namespace" do
        Rsxml::Sexp.unqualify_attrs([{""=>"http://default.com/default", "foo"=>"http://foo.com/foo"}], {"foo:bar"=>"barbar", "baz"=>"bazbaz"}).should ==
          {["bar", "foo", "http://foo.com/foo"]=>"barbar", "baz"=>"bazbaz"}
      end
    end

    describe "qualify_name" do
      it "should produce a qname from a pair or triple" do
        Rsxml::Sexp.qualify_name([{"foo"=>"http://foo.com/foo"}], 
                                 ["bar", "foo"]).should ==
          "foo:bar"
        Rsxml::Sexp.qualify_name([{"foo"=>"http://foo.com/foo"}], 
                                 ["bar", "foo", "http://foo.com/foo"]).should ==
          "foo:bar"
      end

      it "should produce a qname with default namespace" do
        Rsxml::Sexp.qualify_name([{""=>"http://foo.com/foo"}], 
                                 ["bar", ""]).should ==
          "bar"

        Rsxml::Sexp.qualify_name([{""=>"http://foo.com/foo"}], 
                                 ["bar", "", "http://foo.com/foo"]).should ==
          "bar"
      end

      it "should do nothing to a String" do
        Rsxml::Sexp.qualify_name([], "foo:bar").should == "foo:bar"
      end

      it "should raise an error if prefix is nil but uri is not" do
        lambda {
          Rsxml::Sexp.qualify_name([], ["bar", nil, "http://foo.com/foo"])
        }.should raise_error(/invalid name/)
      end

      it "should raise an error if a prefix is not bound" do
        lambda {
          Rsxml::Sexp.qualify_name([], 
                                   ["bar", "foo", "http://foo.com/foo"])
        }.should raise_error(/not bound/)
      end

      it "should raise an error if a prefix binding clashes" do
        lambda {
          Rsxml::Sexp.qualify_name([{"foo"=>"http://foo.com/foo"}], 
                                   ["bar", "foo", "http://bar.com/bar"])
        }.should raise_error(/'foo' is bound/)
      end

      it "should raise an error if default namespace binding clashes" do
        lambda {
          Rsxml::Sexp.qualify_name([{""=>"http://foo.com/foo"}], 
                                   ["bar", "", "http://bar.com/bar"])
        }.should raise_error(/'' is bound/)
      end

    end

    describe "extract_declared_namespaces" do
      it "should extract a hash of declared namespace bindings from a Hash of attributes" do
        Rsxml::Sexp.extract_declared_namespaces({"xmlns"=>"http://default.com/default", "xmlns:foo"=>"http://foo.com/foo", "foo"=>"bar"}).should ==
          {""=>"http://default.com/default", "foo"=>"http://foo.com/foo"}
      end
    end

    describe "extract_explicit_namespaces" do
      it "should extract a hash of explicit namespace bindings from expanded tags" do
        Rsxml::Sexp.extract_explicit_namespaces(["bar", "foo", "http://foo.com/foo"],
                                                {["baz", "bar", "http://bar.com/bar"]=>"baz",
                                                  ["boo", "", "http://default.com/default"]=>"boo"}).should ==
          {"foo"=>"http://foo.com/foo", "bar"=>"http://bar.com/bar", ""=>"http://default.com/default"}
      end

      it "should raise an error if extracted namespaces clash" do
        lambda{
          Rsxml::Sexp.extract_explicit_namespaces(["bar", "foo", "http://foo.com/foo"],
                                                  {["baz", "foo", "http://bar.com/bar"]=>"baz",
                                                    ["boo", "", "http://default.com/default"]=>"boo"})
        }.should raise_error(/bindings clash/)
      end
    end

    describe "undeclared_namespaces" do
      it "should determine which explicit namespaces are not declared in context" do
        Rsxml::Sexp.undeclared_namespaces([{""=>"http://default.com/default", "foo"=>"http://foo.com/foo"}], {""=>"http://default.com/default", "foo"=>"http://foo.com/foo", "bar"=>"http://bar.com/bar"}).should ==
          {"bar"=>"http://bar.com/bar"}
      end

      it "should raise an exception if an explicit prefix clashes with a declard prefix" do
        lambda {
          Rsxml::Sexp.undeclared_namespaces([{""=>"http://default.com/default", "foo"=>"http://foo.com/foo"}], {""=>"http://foo.com/foo", "foo"=>"http://foo.com/foo", "bar"=>"http://bar.com/bar"})
        }.should raise_error(/is bound to uri/)
      end
    end

    describe "merge_namespace_bindings" do
      it "should merge two sets of namespace bindings" do
        Rsxml::Sexp.merge_namespace_bindings({""=>"http://default.com/default",
                                               "boo"=>"http://boo.com/boo"},
                                             {"foo"=>"http://foo.com/foo",
                                               "bar"=>"http://bar.com/bar"}).should ==
          {""=>"http://default.com/default",
          "boo"=>"http://boo.com/boo",
          "foo"=>"http://foo.com/foo",
          "bar"=>"http://bar.com/bar"}
      end

      it "should raise an error if there are binding clashes" do
        lambda {
          Rsxml::Sexp.merge_namespace_bindings({""=>"http://default.com/default",
                                                 "boo"=>"http://boo.com/boo"},
                                               {""=>"http://foo.com/foo",
                                                 "bar"=>"http://bar.com/bar"})
        }.should raise_error(/bindings clash/)
      end
    end

    describe "unqualified_namespace_declarations" do
      it "should produce unqalified namespaces declarations" do
        Rsxml::Sexp.unqualified_namespace_declarations({""=>"http://default.com/default", "foo"=>"http://foo.com/foo"}).should == 
          {"xmlns"=>"http://default.com/default", ["foo", "xmlns"]=>"http://foo.com/foo"}
      end
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
      xml = Rsxml.to_xml([["foofoo", "foo", "http://foo.com/foo"], {["bar", "foo", "http://foo.com/foo"]=>"1", ["baz", "foo", "http://foo.com/foo"]=>"baz"}])

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
