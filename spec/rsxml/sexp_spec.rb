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
  end


  describe "traverse" do
    
  end
end
