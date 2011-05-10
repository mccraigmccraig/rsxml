require File.expand_path("../../spec_helper", __FILE__)

module Rsxml
    describe "find_namespace" do
      it "should find a namespace uri in a stack of prefix bindings" do
        Rsxml::Sexp.find_namespace_uri([{"foo"=>"http://foo.com/foo"},
                                    {"bar"=>"http://bar.com/bar"}],
                                   "bar").should == "http://bar.com/bar"
        Rsxml::Sexp.find_namespace_uri([{"foo"=>"http://foo.com/foo"},
                                    {"bar"=>"http://bar.com/bar"}],
                                   "foo").should == "http://foo.com/foo"
      end

      it "should return nil if there is no matching binding" do
        Rsxml::Sexp.find_namespace_uri([{"foo"=>"http://foo.com/foo"},
                                    {"bar"=>"http://bar.com/bar"}],
                                   "blah").should == nil
        Rsxml::Sexp.find_namespace_uri([],
                                   "blah").should == nil
      end

      
    end

    describe "explode_qname" do
      it "should do nothing to an array with more than one element" do
        Rsxml::Sexp.explode_qname([], ["bar", "foo", "http://foo.com/foo"]).should ==
          ["bar", "foo", "http://foo.com/foo"]
        Rsxml::Sexp.explode_qname([], ["bar", "foo"]).should ==
          ["bar", "foo"]
      end

      it "should return the first element of an array with only the first non-nil element" do
        Rsxml::Sexp.explode_qname([], ["bar"]).should ==
          "bar"
      end

      it "should raise an error if prefix is nil but uri is not" do
        lambda {
          Rsxml::Sexp.explode_qname([], ["bar", nil, "http://foo.com/foo"])
        }.should raise_error(/invalid name/)
      end

      it "should unqualify an unprefixed name with no default namespace" do
        Rsxml::Sexp.explode_qname([], "bar").should == "bar"
      end

      it "should unqualify an unprefixed name in the default namespace" do
        Rsxml::Sexp.explode_qname([{""=>"http://foo.com/foo"}], "bar").should == 
          ["bar", "", "http://foo.com/foo"]
      end

      it "should unqualify a prefixed name with a bound namespace" do
        Rsxml::Sexp.explode_qname([{"foo"=>"http://foo.com/foo"}], "foo:bar").should ==
          ["bar", "foo", "http://foo.com/foo"]
      end

      it "should raise an error with a prefixed name with no bound namespace" do
        lambda {
          Rsxml::Sexp.explode_qname([], "foo:bar")
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

    describe "compact_attr_qnames" do
      it "should qualify attribute names when there is a default namespaces" do
        Rsxml::Sexp.compact_attr_qnames([{""=>"http://default.com/default","foo"=>"http://foo.com/foo"}], {["bar", "foo"] => "barbar", ["boo", ""] => "booboo", "baz" =>"bazbaz"}).should ==
          {"foo:bar"=>"barbar", "boo"=>"booboo", "baz"=>"bazbaz"}
      end

      it "should raise an exception if a namespace is referenced but not bound" do
        lambda {
          Rsxml::Sexp.compact_attr_qnames([], {["bar", "foo"] => "barbar", "baz" =>"bazbaz"})
        }.should raise_error(/not bound/)
      end

      it "should raise an exception if default namespace referenced but not bound" do
        lambda {
          Rsxml::Sexp.compact_attr_qnames([{"foo"=>"http://foo.com/foo"}], {["bar", "foo"] => "barbar", ["boo", ""] => "booboo", "baz" =>"bazbaz"})
        }.should raise_error(/not bound/)
      end
    end

    describe "explode_attr_qnames" do
      it "should unqualify attributes when there is no default namespace" do
        Rsxml::Sexp.explode_attr_qnames([{"foo"=>"http://foo.com/foo"}], {"foo:bar"=>"barbar", "baz"=>"bazbaz"}).should ==
          {["bar", "foo", "http://foo.com/foo"]=>"barbar", "baz"=>"bazbaz"}
      end

      it "should unqualify attributes when there is a default namespace" do
        Rsxml::Sexp.explode_attr_qnames([{""=>"http://default.com/default", "foo"=>"http://foo.com/foo"}], {"foo:bar"=>"barbar", "baz"=>"bazbaz"}).should ==
          {["bar", "foo", "http://foo.com/foo"]=>"barbar", "baz"=>"bazbaz"}
      end
    end

    describe "compact_qname" do
      it "should produce a qname from a pair or triple" do
        Rsxml::Sexp.compact_qname([{"foo"=>"http://foo.com/foo"}], 
                                 ["bar", "foo"]).should ==
          "foo:bar"
        Rsxml::Sexp.compact_qname([{"foo"=>"http://foo.com/foo"}], 
                                 ["bar", "foo", "http://foo.com/foo"]).should ==
          "foo:bar"
      end

      it "should produce a qname with default namespace" do
        Rsxml::Sexp.compact_qname([{""=>"http://foo.com/foo"}], 
                                 ["bar", ""]).should ==
          "bar"

        Rsxml::Sexp.compact_qname([{""=>"http://foo.com/foo"}], 
                                 ["bar", "", "http://foo.com/foo"]).should ==
          "bar"
      end

      it "should do nothing to a String" do
        Rsxml::Sexp.compact_qname([], "foo:bar").should == "foo:bar"
      end

      it "should raise an error if prefix is nil but uri is not" do
        lambda {
          Rsxml::Sexp.compact_qname([], ["bar", nil, "http://foo.com/foo"])
        }.should raise_error(/invalid name/)
      end

      it "should raise an error if a prefix is not bound" do
        lambda {
          Rsxml::Sexp.compact_qname([], 
                                   ["bar", "foo", "http://foo.com/foo"])
        }.should raise_error(/not bound/)
      end

      it "should raise an error if a prefix binding clashes" do
        lambda {
          Rsxml::Sexp.compact_qname([{"foo"=>"http://foo.com/foo"}], 
                                   ["bar", "foo", "http://bar.com/bar"])
        }.should raise_error(/'foo' is bound/)
      end

      it "should raise an error if default namespace binding clashes" do
        lambda {
          Rsxml::Sexp.compact_qname([{""=>"http://foo.com/foo"}], 
                                   ["bar", "", "http://bar.com/bar"])
        }.should raise_error(/'' is bound/)
      end

    end

    describe "extract_declared_namespace_bindings" do
      it "should extract a hash of declared namespace bindings from a Hash of attributes" do
        Rsxml::Sexp.extract_declared_namespace_bindings({"xmlns"=>"http://default.com/default", "xmlns:foo"=>"http://foo.com/foo", "foo"=>"bar"}).should ==
          {""=>"http://default.com/default", "foo"=>"http://foo.com/foo"}
      end
    end

    describe "extract_explicit_namespace_bindings" do
      it "should extract a hash of explicit namespace bindings from expanded tags" do
        Rsxml::Sexp.extract_explicit_namespace_bindings(["bar", "foo", "http://foo.com/foo"],
                                                {["baz", "bar", "http://bar.com/bar"]=>"baz",
                                                  ["boo", "", "http://default.com/default"]=>"boo"}).should ==
          {"foo"=>"http://foo.com/foo", "bar"=>"http://bar.com/bar", ""=>"http://default.com/default"}
      end

      it "should raise an error if extracted namespaces clash" do
        lambda{
          Rsxml::Sexp.extract_explicit_namespace_bindings(["bar", "foo", "http://foo.com/foo"],
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
