require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
  describe "traverse" do
    it "should call the element function on the visitor" do
      visitor = Visitor::MockVisitor.new([[:element, :_, "foo", {}, {}]])
      Sexp.traverse([:foo], visitor)
      visitor.__finalize__
    end
  end

  describe "decompose_sexp" do
    it "should decompose a [element_name] sexp" do
      Sexp.decompose_sexp(["foo"]).should == ["foo", {}, []]
    end

    it "should decompose a [element_name, attrs] sexp" do
      Sexp.decompose_sexp(["foo", {"foofoo"=>"a"}]).should == ["foo", {"foofoo"=>"a"}, []]
    end

    it "should decompose a [element_name, attrs, children] sexp" do
      Sexp.decompose_sexp(["foo", {"foofoo"=>"a"}, ["bar"], ["baz"]]).should == ["foo", {"foofoo"=>"a"}, [["bar"], ["baz"]]]
    end
  end

  describe "compare" do
  end
end
