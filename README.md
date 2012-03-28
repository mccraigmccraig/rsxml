rsxml [![Build Status](http://travis-ci.org/trampoline/rsxml.png)](http://travis-ci.org/trampoline/rsxml)
=====

Ruby literal representation of XML documents in the style of [SXML](http://en.wikipedia.org/wiki/SXML)

Installation
------------

    $ gem install rsxml


Background
----------

Rsxml is a Ruby library to translate XML documents into an s-expression style Ruby literal representation, using Array and Hash literals, and back again

Why would you want to do this ? Ruby literals :

* can be == compared natively
* are easy to read
* can be indented nicely by editors
* can be syntax checked and balanced by editors

These features make them nice for writing readable XML generation code and readable tests for XML generating code

Rsxml uses [Nokogiri](http://nokogiri.org/) for parsing XML, and [Builder](http://builder.rubyforge.org/) for generating it. Rsxml is not a feature complete XML processor : It does not attempt to process PIs, CDATA etc, but it does make it very easy to use and generate straightforward XML documents from Ruby

Use
---

Rsxml represents XML documents as s-expressions comprised of Ruby Array and Hash literals, thus :

     ["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"], ["Baz"]]

represents the XML document :

     <Foo foofoo="10"><Bar>barbar</Bar><Baz></Baz></Foo>

It is easy to convert XML docuemnts to Rsxml representation and back again :

     xml = Rsxml.to_xml(["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"]])
       => '<Foo foofoo="10"><Bar>barbar</Bar></Foo>'

     Rsxml.to_rsxml(xml)
       => ["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"]]

### Namespaces

XML namespaces are dealt with straightforwardly. When an XML document is converted to Rsxml, namespaces are preserved, and you can specify namespaces in an Rsxml structure in two ways, which can be freely mixed

* using QName prefixes and declarative attributes, exactly as with XML
* using exploded QNames consisting of <tt>[local_part, prefix, uri]</tt> triples and <tt>[local_part, prefix]</tt> pairs

### Converting to Rsxml


When you convert an XML document to Rsxml you can choose either <tt>:xml</tt> or <tt>:exploded</tt> style

#### <tt>:xml</tt> style

In <tt>:xml</tt> style namespaces are declared using attributes, and namespaces are referenced using
`prefix:LocalPart` QNames, as in XML

     Rsxml.to_rsxml('<foo:foofoo xmlns:foo="http://foo.com/foo" foo:bar="barbar"/>', :style=>:xml)
       => ["foo:foofoo", {"foo:bar"=>"barbar", "xmlns:foo"=>"http://foo.com/foo"}] 

#### <tt>:exploded</tt> style

In <tt>:exploded</tt> style namespaces are not declared using attributes, and QNames are specified
using <tt>[local_part, prefix, uri]</tt> triples

     Rsxml.to_rsxml('<foo:foofoo xmlns:foo="http://foo.com/foo" foo:bar="barbar"/>', :style=>:exploded)
       => [["foofoo", "foo", "http://foo.com/foo"], {["bar", "foo", "http://foo.com/foo"]=>"barbar"}]

### Converting to XML

Rsxml styles can be mixed, and replicated namespace references can be skipped (i.e. `[local_part,prefix]` pairs can be used instead of `[local_part, prefix, uri]` triples) for readability

     Rsxml.to_xml([["foofoo", "foo", "http://foo.com/foo"], {"foo:bar"=>"1", ["baz", "foo"]=>"2"}])
       => '<foo:foofoo foo:baz="2" foo:bar="1" xmlns:foo="http://foo.com/foo"></foo:foofoo>'

### Fragments

XML Fragments, without proper namespace declarations, can be parsed by passing a Hash of namespace
prefix bindings

     Rsxml.to_rsxml('<foo:foofoo foo:bar="barbar"/>', :ns=>{"foo"=>"http://foo.com/foo"}, :style=>:xml)
       => ["foo:foofoo", {"foo:bar"=>"barbar"}] 

Fragments can be generated similarly :

     Rsxml.to_xml(["foo:foofoo", {"foo:bar"=>"barbar"}], :ns=>{"foo"=>"http://foo.com/foo"})
       => '<foo:foofoo foo:bar="barbar"></foo:foofoo>'

### Visitors

<tt>Rsxml.to_rsxml</tt> and <tt>Rsxml.to_xml</tt> are implemented with a simple Visitor pattern over the XML document structure. <tt>Rsxml::Sexp.traverse()</tt> traverses a Rsxml s-expression representation of an XML document and <tt>Rsxml::Xml.traverse()</tt> traverses a Nokogiri Node tree. The Visitor receives a

     text(context, text)

invocation for each text node, and an

     element(context, name, attrs, ns_decls)

method invocation for each element. If namespaces are used, element and attribute names in the <tt>element</tt> method invocations are exploded <tt>[local_part, prefix, uri]</tt> triples. The attributes are presented as a <tt>{name=>value}</tt> `Hash` which contains no namespace-related attributes. Any namespace declarations for the element are provided as the <tt>{prefix=>uri}</tt> `ns_decls` `Hash`. Namespace prefixes, URIs and declaration attributes are cleanly separated in this API, so it is easy for Visitor implementations to correctly process XML documents with namespaces

Contributing to rsxml
---------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2012 mccraigmccraig of the clan mccraig. See LICENSE.txt for
further details.

