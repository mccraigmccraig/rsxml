require File.expand_path("../../spec_helper", __FILE__)
require 'rsxml/visitor'
require 'rsxml/mock_visitor'

module Rsxml
  # tests traverse methods on both Xml and Sexp together : they should produce identical visitation
  # patterns
  describe "traverse" do
    def check_traverse(expectations, xml, sexp)
      xml_visitor = Visitor::MockVisitor.new(expectations)
      xml_root = Nokogiri::XML(xml).children.first
      Xml.traverse(xml_root, xml_visitor)
      xml_visitor.__finalize__

      sexp_visitor = Visitor::MockVisitor.new(expectations)
      Sexp.traverse(sexp, sexp_visitor)
      sexp_visitor.__finalize__
    end

    it "should call the element function on the visitor" do
      check_traverse([[:element, :_, "foo", {"bar"=>"barbar"}, {}]],
                     '<foo bar="barbar"/>',
                     [:foo, {"bar"=>"barbar"}])
    end

    it "should call the element function on the visitor with exploded element and attributes qnames" do
      check_traverse([[:element, :_,
                       ["foofoo", "foo", "http://foo.com/foo"],
                       {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                       {"foo"=>"http://foo.com/foo"}]],
                     '<foo:foofoo foo:bar="barbar" xmlns:foo="http://foo.com/foo"/>',
                     [["foofoo", "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"}])
    end

    it "should call the test function on the visitor with textual content" do
      check_traverse([[:element, :_,
                       ["foofoo", "foo", "http://foo.com/foo"],
                       {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                       {"foo"=>"http://foo.com/foo"}],
                      [:text, :_, "boohoo"]],
                     '<foo:foofoo foo:bar="barbar" xmlns:foo="http://foo.com/foo">boohoo</foo:foofoo>',
                     [["foofoo", "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"}, "boohoo"])
    end

    it "should call the element function in document order for each element in a hierarchic doc" do
      check_traverse([[:element, :_,
                       ["foofoo", "foo", "http://foo.com/foo"],
                       {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                       {"foo"=>"http://foo.com/foo"}],
                      [:element, :_,
                       ["barbar", "foo", "http://foo.com/foo"],
                       {["baz", "foo", "http://foo.com/foo"]=>"bazbaz"},
                       {}]],
                     '<foo:foofoo foo:bar="barbar" xmlns:foo="http://foo.com/foo"><foo:barbar foo:baz="bazbaz"/></foo:foofoo>',
                     [["foofoo", "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                      [["barbar", "foo"], {["baz", "foo"]=>"bazbaz"}]])
    end

    it "should call the element/text functions in a mixed document in document order" do
      check_traverse([[:element, :_,
                       ["foofoo", "foo", "http://foo.com/foo"],
                       {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                       {"foo"=>"http://foo.com/foo"}],
                      [:element, :_,
                       ["barbar", "foo", "http://foo.com/foo"],
                       {["baz", "foo", "http://foo.com/foo"]=>"bazbaz"},
                       {}],
                      [:text, :_, "sometext"],
                      [:element, :_, "boo", {"hoo"=>"hoohoo"}, {"zoo"=>"http://zoo.com/zoo"}],
                      [:element, :_, ["bozo", "zoo", "http://zoo.com/zoo"], {}, {}]
                     ],
                     '<foo:foofoo foo:bar="barbar" xmlns:foo="http://foo.com/foo"><foo:barbar foo:baz="bazbaz"/>sometext<boo hoo="hoohoo" xmlns:zoo="http://zoo.com/zoo"><zoo:bozo/></boo></foo:foofoo>',
                     [["foofoo", "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                      [["barbar", "foo"], {["baz", "foo"]=>"bazbaz"}],
                      "sometext",
                      ["boo", {"hoo"=>"hoohoo", "xmlns:zoo"=>"http://zoo.com/zoo"},
                       ["zoo:bozo"]]])
    end

    it "should work the same with compact sexp representations" do
      check_traverse([[:element, :_,
                       ["foofoo", "foo", "http://foo.com/foo"],
                       {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                       {"foo"=>"http://foo.com/foo"}],
                      [:element, :_,
                       ["barbar", "foo", "http://foo.com/foo"],
                       {["baz", "foo", "http://foo.com/foo"]=>"bazbaz"},
                       {}],
                      [:text, :_, "sometext"],
                      [:element, :_, "boo", {"hoo"=>"hoohoo"}, {"zoo"=>"http://zoo.com/zoo"}],
                      [:element, :_, ["bozo", "zoo", "http://zoo.com/zoo"], {}, {}]
                     ],
                     '<foo:foofoo foo:bar="barbar" xmlns:foo="http://foo.com/foo"><foo:barbar foo:baz="bazbaz"/>sometext<boo hoo="hoohoo" xmlns:zoo="http://zoo.com/zoo"><zoo:bozo/></boo></foo:foofoo>',
                     ["foo:foofoo", {"foo:bar"=>"barbar", "xmlns:foo"=>"http://foo.com/foo"},
                      ["foo:barbar", {"foo:baz"=>"bazbaz"}],
                      "sometext",
                      ["boo", {"hoo"=>"hoohoo", "xmlns:zoo"=>"http://zoo.com/zoo"},
                       ["zoo:bozo"]]])
    end

  end

  describe Visitor::WriteXmlVisitor do
    it "should write single element xml" do
      Sexp::traverse(["item"], Visitor::WriteXmlVisitor.new).to_s.should == "<item></item>"
    end

    it "should write single element xml with attributes" do
      Sexp::traverse([:item, {:foo=>"100"}], Visitor::WriteXmlVisitor.new).to_s.should == '<item foo="100"></item>'
    end

    it "should write nested elements with attributes and text content" do
      Sexp::traverse([:item, {:foo=>"100"}, [:bar], "foofoo", [:baz]], Visitor::WriteXmlVisitor.new).to_s.should == '<item foo="100"><bar></bar>foofoo<baz></baz></item>'
    end

    it "should permit lazy declaration of namespces" do
      root = Nokogiri::XML(Sexp::traverse([[:bar, "foo", "http://foo.com/foo"], {"foo:foofoo"=>"fff"}], Visitor::WriteXmlVisitor.new).to_s).children.first
      root.namespaces.should == {"xmlns:foo"=>"http://foo.com/foo"}

      root.name.should == 'bar'
      root.namespace.prefix.should == 'foo'
      root.namespace.href.should == 'http://foo.com/foo'

      root.attributes["foofoo"].value.should == "fff"
      root.attributes["foofoo"].namespace.prefix.should == 'foo'
      root.attributes["foofoo"].namespace.href.should == 'http://foo.com/foo'
    end
  end

  describe Visitor::BuildRsxmlVisitor do
    describe "compact_qname" do
      it "should compact exploded qnames" do
        Visitor::BuildRsxmlVisitor.new.compact_qname(["foo", "bar", "http://bar.com/bar"]).should ==
          "bar:foo"
        Visitor::BuildRsxmlVisitor.new.compact_qname("foo").should ==
          "foo"
      end
    end

    describe "compact_attr_names" do
      it "should compact exploded attribute names" do
        Visitor::BuildRsxmlVisitor.new.compact_attr_names({["foo", "bar", "http://bar.com/bar"]=>"foofoo", "baz"=>"bazbaz", ["foofoo", "bar"]=>"fff"}).should ==
          {"bar:foo"=>"foofoo", "baz"=>"bazbaz", "bar:foofoo"=>"fff"}
      end
    end

    describe "element" do
      it "should append the rsxml element to the cursor element and yield" do
      end
    end

    describe "text" do
      it "should append the text to the cursor element" do
      end
    end

    it "should read a single element document" do
      root = Nokogiri::XML('<foo></foo>').children.first
      rsxml = Rsxml::Xml.traverse(root, Visitor::BuildRsxmlVisitor.new).sexp
      rsxml.should == ["foo"]
    end

    it "should read a single element document with attributes" do
      root = Nokogiri::XML('<foo bar="10" baz="20"></foo>').children.first
      rsxml = Rsxml::Xml.traverse(root, Visitor::BuildRsxmlVisitor.new).sexp
      rsxml.should == ["foo", {"bar"=>"10", "baz"=>"20"}]
    end

    describe "element_transformer" do
      def capitalize_local_part(qname)
        local_part, prefix, uri = qname
        if uri
          [local_part.capitalize, prefix, uri]
        else
          local_part.capitalize
        end
      end

      it "should call a element_transformer block to transform element_names and attrs" do
        root = Nokogiri::XML('<foo bar="10" baz="20"></foo>').children.first
        rsxml = Rsxml::Xml.traverse(root, Visitor::BuildRsxmlVisitor.new do |context,element_name,attrs|
                                      celement_name = capitalize_local_part(element_name)
                                      cattrs = Hash[attrs.map{|n,v| [capitalize_local_part(n), v]}]
                                      [celement_name, cattrs]
                                    end ).sexp

        rsxml.should ==
          ["Foo", {"Bar"=>"10", "Baz"=>"20"}]

        root = Nokogiri::XML('<a:foo bar="10" baz="20" xmlns:a="http://a.com/a"></a:foo>').children.first
        rsxml = Rsxml::Xml.traverse(root, Visitor::BuildRsxmlVisitor.new(:style=>:exploded) do |context,element_name,attrs|
                                      celement_name = capitalize_local_part(element_name)
                                      cattrs = Hash[attrs.map{|n,v| [capitalize_local_part(n), v]}]
                                      [celement_name, cattrs]
                                    end ).sexp

        rsxml.should ==
          [["Foo", "a", "http://a.com/a"], {"Bar"=>"10", "Baz"=>"20"}]

      end
    end
  end

end
