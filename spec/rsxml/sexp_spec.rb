require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
  describe "traverse" do
    it "should call the element function on the visitor" do
      visitor = Visitor::MockVisitor.new([[:element, :_, "foo", {"bar"=>"barbar"}, {}]])
      Sexp.traverse([:foo, {"bar"=>"barbar"}], visitor)
      visitor.__finalize__
    end

    it "should call the element function on the visitor with exploded element and attributes qnames" do
      visitor = Visitor::MockVisitor.new([[:element, :_, 
                                           [:foofoo, "foo", "http://foo.com/foo"], 
                                           {["bar", "foo", "http://foo.com/foo"]=>"barbar"}, 
                                           {"foo"=>"http://foo.com/foo"}]])
      Sexp.traverse([[:foofoo, "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"}], visitor)
      visitor.__finalize__
    end

    it "should call the test function on the visitor with textual content" do
      visitor = Visitor::MockVisitor.new([[:element, :_, 
                                           [:foofoo, "foo", "http://foo.com/foo"], 
                                           {["bar", "foo", "http://foo.com/foo"]=>"barbar"}, 
                                           {"foo"=>"http://foo.com/foo"}],
                                          [:text, :_, "boohoo"]])
      Sexp.traverse([[:foofoo, "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"}, "boohoo"], visitor)
      visitor.__finalize__
    end

    it "should call the element function in document order for each element in a hierarchic doc" do
      visitor = Visitor::MockVisitor.new([[:element, :_, 
                                           [:foofoo, "foo", "http://foo.com/foo"], 
                                           {["bar", "foo", "http://foo.com/foo"]=>"barbar"}, 
                                           {"foo"=>"http://foo.com/foo"}],
                                          [:element, :_,
                                           [:barbar, "foo", "http://foo.com/foo"],
                                           {["baz", "foo", "http://foo.com/foo"]=>"bazbaz"},
                                           {}]])
      Sexp.traverse([[:foofoo, "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                     [[:barbar, "foo"], {["baz", "foo"]=>"bazbaz"}]], visitor)
      visitor.__finalize__
    end

    it "should call the element/text functions in a mixed document in document order" do
      visitor = Visitor::MockVisitor.new([[:element, :_, 
                                           [:foofoo, "foo", "http://foo.com/foo"], 
                                           {["bar", "foo", "http://foo.com/foo"]=>"barbar"}, 
                                           {"foo"=>"http://foo.com/foo"}],
                                          [:element, :_,
                                           [:barbar, "foo", "http://foo.com/foo"],
                                           {["baz", "foo", "http://foo.com/foo"]=>"bazbaz"},
                                           {}],
                                          [:text, :_, "sometext"],
                                          [:element, :_, "boo", {"hoo"=>"hoohoo"}, {"zoo"=>"http://zoo.com/zoo"}],
                                          [:element, :_, ["bozo", "zoo", "http://zoo.com/zoo"], {}, {}]
                                         ])
      Sexp.traverse([[:foofoo, "foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"},
                     [[:barbar, "foo"], {["baz", "foo"]=>"bazbaz"}],
                     "sometext",
                     ["boo", {"hoo"=>"hoohoo", "xmlns:zoo"=>"http://zoo.com/zoo"},
                      ["zoo:bozo"]]], visitor)
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
