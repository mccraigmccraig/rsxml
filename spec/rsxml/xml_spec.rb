require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
  describe "wrap_fragment" do
    it "should do nothing if there are no ns_prefixes" do
    end

    it "should wrap a fragment in a document with namespace declarations if there are ns prefixes" do
    end
  end

  describe "unwrap_fragment" do
    it "should do nothing if there is no wrapping element" do
    end

    it "should remove the outermost element if it is a wrapping element" do
    end

    it "should throw an exception if it unwraps and there is more than one child" do
    end
  end

  describe "explode_node" do
    it "should return the element name String if there is no namespace" do
      node = Object.new
      stub(node).name{"foo"}
      stub(node).namespace{nil}
      Xml.explode_node(node).should == "foo"
    end

    it "should return the [local_name, prefix, uri] triple if there is a namespace" do
      node = Object.new
      stub(node).name{"foo"}
      namespace = Object.new
      stub(node).namespace{namespace}
      stub(namespace).prefix{"bar"}
      stub(namespace).href{"http://bar.com/bar"}
      Xml.explode_node(node).should == ["foo", "bar", "http://bar.com/bar"]
    end

    it "should return a [local_name, "", uri] triple if there is a default namespace" do
      node = Object.new
      stub(node).name{"foo"}
      namespace = Object.new
      stub(node).namespace{namespace}
      stub(namespace).prefix{nil}
      stub(namespace).href{"http://bar.com/bar"}
      Xml.explode_node(node).should == ["foo", "", "http://bar.com/bar"]
    end
  end

  describe "explode_element" do
    it "should explode an element and it's attributes" do
      root = Nokogiri::XML('<foo:bar a="aa" foo:b="bb" xmlns:foo="http://foo.com/foo" xmlns="http://default.com/default"></foo:bar>').children.first

      eelement, eattrs = Rsxml::Xml.explode_element(root)
      eelement.should == ["bar", "foo", "http://foo.com/foo"]
      eattrs.should == {"a"=>"aa", ["b", "foo", "http://foo.com/foo"]=>"bb"}
    end
  end

  describe Xml::ConstructRsxmlVisitor do
    it "should read a single element document" do
      root = Nokogiri::XML('<foo></foo>').children.first
      rsxml = Rsxml::Xml.traverse(root, Xml::ConstructRsxmlVisitor.new).sexp
      rsxml.should == ["foo"]
    end

    it "should read a single element document with attributes" do
      root = Nokogiri::XML('<foo bar="10" baz="20"></foo>').children.first
      rsxml = Rsxml::Xml.traverse(root, Xml::ConstructRsxmlVisitor.new).sexp
      rsxml.should == ["foo", {"bar"=>"10", "baz"=>"20"}]
    end
  end

  describe "read_xml" do

    it "should explode qnames if given the :explode=>true option" do
    end
  end
end
