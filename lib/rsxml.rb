$: << File.expand_path('../../lib', __FILE__)

require 'nokogiri'
require 'builder'
require 'rsxml/namespace'
require 'rsxml/visitor'
require 'rsxml/sexp'
require 'rsxml/xml'

module Rsxml
  class << self
    attr_accessor :logger
  end

  module_function

  def log
    yield(logger) if logger
  end

  def check_opts(constraints, opts)
    (opts||{}).each do |k,v|
      raise "opt not permitted: #{k}" if !constraints.has_key?(k)
      constraint = constraints[k]
    end
  end

  # convert an Rsxml s-expression representation of an XML document to XML
  #  Rsxml.to_xml(["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"] ["Baz"]])
  #   => '<Foo foofoo="10"><Bar>barbar</Bar><Baz></Baz></Foo>' 
  def to_xml(rsxml, &transformer)
    Sexp.traverse(rsxml, Sexp::WriteXmlVisitor.new).to_s
  end

  TO_RSXML_OPTS = {:ns=>nil}

  # convert an XML string to an Rsxml s-expression representation
  #  Rsxml.to_rsxml('<Foo foofoo="10"><Bar>barbar</Bar><Baz></Baz></Foo>')
  #   => ["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"], ["Baz"]] 
  #
  # if <tt>ns_prefixes</tt> is a Hash, then +doc+ is assumed to be a 
  # fragment, and is wrapped in an element with namespace declarations
  # according to +ns_prefixes+
  #  fragment = '<foo:Foo foo:foofoo="10"><Bar>barbar</Bar><Baz></Baz></Foo>'
  #  Rsxml.to_rsxml(fragment, {"foo"=>"http://foo.com/foo", ""=>"http://baz.com/baz"})
  #   => ["foo:Foo", {"foo:foofoo"=>"10", "xmlns:foo"=>"http://foo.com/foo", "xmlns"=>"http://baz.com/baz"}, ["Bar", "barbar"], ["Baz"]]
  def to_rsxml(doc, opts={})
    check_opts(TO_RSXML_OPTS, opts)
    doc = Xml.wrap_fragment(doc, opts[:ns])
    root = Xml.unwrap_fragment(Nokogiri::XML(doc).children.first)
    Xml.read_xml(root)
  end

  # compare two documents in XML or Rsxml. returns +true+ if they are identical, and
  # if not raises +ComparisonError+ describing where they differ
  def compare(xml_or_sexp_a, xml_or_sexp_b)
    sexp_a = xml_or_sexp_a.is_a?(String) ? to_rsxml(xml_or_sexp_a) : xml_or_sexp_a
    sexp_b = xml_or_sexp_b.is_a?(String) ? to_rsxml(xml_or_sexp_b) : xml_or_sexp_b
    Sexp.compare(sexp_a, sexp_b)
  end

end
