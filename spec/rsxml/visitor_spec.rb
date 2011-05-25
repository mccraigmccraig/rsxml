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

    describe "tag_transformer" do
      def capitalize_local_name(qname)
        local_name, prefix, uri = qname
        if uri
          [local_name.capitalize, prefix, uri]
        else
          local_name.capitalize
        end
      end

      it "should call a tag_transformer block to transform tags and attrs" do
        root = Nokogiri::XML('<foo bar="10" baz="20"></foo>').children.first
        rsxml = Rsxml::Xml.traverse(root, Visitor::BuildRsxmlVisitor.new do |context,tag,attrs|
                                      ctag = capitalize_local_name(tag)
                                      cattrs = Hash[attrs.map{|n,v| [capitalize_local_name(n), v]}]
                                      [ctag, cattrs]
                                    end ).sexp
                                        
        rsxml.should ==
          ["Foo", {"Bar"=>"10", "Baz"=>"20"}]

        root = Nokogiri::XML('<a:foo bar="10" baz="20" xmlns:a="http://a.com/a"></a:foo>').children.first
        rsxml = Rsxml::Xml.traverse(root, Visitor::BuildRsxmlVisitor.new(:style=>:exploded) do |context,tag,attrs|
                                      ctag = capitalize_local_name(tag)
                                      cattrs = Hash[attrs.map{|n,v| [capitalize_local_name(n), v]}]
                                      [ctag, cattrs]
                                    end ).sexp
                                        
        rsxml.should ==
          [["Foo", "a", "http://a.com/a"], {"Bar"=>"10", "Baz"=>"20"}]

      end
    end
  end

end
