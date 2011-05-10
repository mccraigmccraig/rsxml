require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
  describe Sexp::WriteXmlVisitor do
    it "should write single element xml" do
      Sexp::traverse(["item"], Sexp::WriteXmlVisitor.new).to_s.should == "<item></item>"
    end

    it "should write single element xml with attributes" do
      Sexp::traverse([:item, {:foo=>"100"}], Sexp::WriteXmlVisitor.new).to_s.should == '<item foo="100"></item>'
    end

    it "should write nested elements with attributes and text content" do
      Sexp::traverse([:item, {:foo=>"100"}, [:bar], "foofoo", [:baz]], Sexp::WriteXmlVisitor.new).to_s.should == '<item foo="100"><bar></bar>foofoo<baz></baz></item>'
    end

    it "should permit lazy declaration of namespces" do
      root = Nokogiri::XML(Sexp::traverse([[:bar, "foo", "http://foo.com/foo"], {"foo:foofoo"=>"fff"}], Sexp::WriteXmlVisitor.new).to_s).children.first
      root.namespaces.should == {"xmlns:foo"=>"http://foo.com/foo"}

      root.name.should == 'bar'
      root.namespace.prefix.should == 'foo'
      root.namespace.href.should == 'http://foo.com/foo'

      root.attributes["foofoo"].value.should == "fff"
      root.attributes["foofoo"].namespace.prefix.should == 'foo'
      root.attributes["foofoo"].namespace.href.should == 'http://foo.com/foo'
    end
  end


  describe "traverse" do
    
  end
end
