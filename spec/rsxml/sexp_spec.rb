require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
  describe "traverse" do
    it "should call the tag function on the visitor" do
    end
  end

  describe "decompose_sexp" do
    it "should decompose a [tag] sexp" do
      Sexp.decompose_sexp(["foo"]).should == ["foo", {}, []]
    end

    it "should decompose a [tag,attrs] sexp" do
      Sexp.decompose_sexp(["foo", {"foofoo"=>"a"}]).should == ["foo", {"foofoo"=>"a"}, []]
    end

    it "should decompose a [tag, attrs, children] sexp" do
      Sexp.decompose_sexp(["foo", {"foofoo"=>"a"}, ["bar"], ["baz"]]).should == ["foo", {"foofoo"=>"a"}, [["bar"], ["baz"]]]
    end
  end

  describe "compare" do
  end
end
