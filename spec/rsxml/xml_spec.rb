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

    it "should return a node with no namespace definitions" do
      root = Xml.unwrap_fragment(Nokogiri::XML(Xml.wrap_fragment("<foo:bar/>", {"foo"=>"http://foo.com/foo"})).children.first)
      root.namespace_definitions.should == []
      root.name.should == "bar"
      root.namespace.prefix.should == "foo"
      root.namespace.href.should == "http://foo.com/foo"
    end
  end

  describe "explode_node" do
    it "should return the element name String if there is no namespace" do
      node = Object.new
      stub(node).name{"foo"}
      stub(node).namespace{nil}
      Xml.explode_node(node).should == "foo"
    end

    it "should return the [local_part, prefix, uri] triple if there is a namespace" do
      node = Object.new
      stub(node).name{"foo"}
      namespace = Object.new
      stub(node).namespace{namespace}
      stub(namespace).prefix{"bar"}
      stub(namespace).href{"http://bar.com/bar"}
      Xml.explode_node(node).should == ["foo", "bar", "http://bar.com/bar"]
    end

    it "should return a [local_part, "", uri] triple if there is a default namespace" do
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
      eattrs.should == {"a"=>"aa", 
        ["b", "foo", "http://foo.com/foo"]=>"bb"}
    end
  end

  describe "traverse" do
  end

end
