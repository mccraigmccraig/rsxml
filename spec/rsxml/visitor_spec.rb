require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
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

  describe Visitor::ConstructRsxmlVisitor do
    it "should read a single element document" do
      root = Nokogiri::XML('<foo></foo>').children.first
      rsxml = Rsxml::Xml.traverse(root, Visitor::ConstructRsxmlVisitor.new).sexp
      rsxml.should == ["foo"]
    end

    it "should read a single element document with attributes" do
      root = Nokogiri::XML('<foo bar="10" baz="20"></foo>').children.first
      rsxml = Rsxml::Xml.traverse(root, Visitor::ConstructRsxmlVisitor.new).sexp
      rsxml.should == ["foo", {"bar"=>"10", "baz"=>"20"}]
    end
  end

end
