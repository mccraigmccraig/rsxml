require 'nokogiri'
require 'builder'

module Rsxml
  module_function

  # convert an Rsxml s-expression representation of an XML document to XML
  #  Rsxml.to_xml(["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"] ["Baz"]])
  #   => '<Foo foofoo="10"><Bar>barbar</Bar><Baz></Baz></Foo>' 
  def to_xml(rsxml)
    xml = Builder::XmlMarkup.new
    Sexp.write_xml(xml, rsxml)
    xml.target!
  end

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
  def to_rsxml(doc, ns_prefixes=nil)
    doc = Xml.wrap_fragment(doc, ns_prefixes)
    root = Xml.unwrap_fragment(Nokogiri::XML(doc).children.first)
    Xml.read_xml(root, [])
  end

  # compare two documents in XML or Rsxml. returns +true+ if they are identical, and
  # if not raises +ComparisonError+ describing where they differ
  def compare(xml_or_sexp_a, xml_or_sexp_b)
    sexp_a = xml_or_sexp_a.is_a?(String) ? to_rsxml(xml_or_sexp_a) : xml_or_sexp_a
    sexp_b = xml_or_sexp_b.is_a?(String) ? to_rsxml(xml_or_sexp_b) : xml_or_sexp_b
    Sexp.compare(sexp_a, sexp_b)
  end

  module Sexp
    module_function

    def write_xml(xml, sexp)
      tag, attrs, children = decompose_sexp(sexp)
      
      xml.__send__(tag, attrs) do
        children.each do |child|
          if child.is_a?(Array)
            write_xml(xml, child)
          else
            xml << child
          end
        end
      end
    end

    def decompose_sexp(sexp)
      raise "invalid rsxml: #{rsxml.inspect}" if sexp.length<1
      tag = sexp[0].to_s
      if sexp[1].is_a?(Hash)
        attrs = sexp[1]
        children = sexp[2..-1]
      else
        attrs = {}
        children = sexp[1..-1]
      end
      [tag, attrs, children]
    end

    class ComparisonError < RuntimeError
      attr_reader :path
      def initialize(msg, path)
        super("[#{path}]: #{msg}")
        @path = path
      end
    end

    def compare(sexpa, sexpb, path=nil)
      taga, attrsa, childrena = decompose_sexp(sexpa)
      tagb, attrsb, childrenb = decompose_sexp(sexpb)

      raise ComparisonError.new("element names differ: '#{taga}', '#{tagb}'", path) if taga != tagb
      raise ComparisonError.new("attributes differ", path) if attrsa != attrsb
      raise ComparisonError.new("child cound differes", path) if childrena.length != childrenb.length

      path = [path, taga].compact.join("/")
      (0...childrena.length).each do |i|
        if childrena[i].is_a?(Array) && childrenb[i].is_a?(Array)
          compare(childrena[i], childrenb[i], path)
        else
          raise ComparisonError.new("content differs: '#{childrena[i]}', '#{childrenb[i]}'", path) if childrena[i] != childrenb[i]
        end
      end
      true
    end
  end

  module Xml
    module_function

    WRAP_ELEMENT = "RsxmlXmlWrapper"

    def wrap_fragment(fragment, ns_prefixes)
      return fragment if !ns_prefixes

      ns_attrs = Hash[*ns_prefixes.map do |prefix,href|
                        prefix = nil if prefix.to_s.length == 0
                        [["xmlns", prefix].compact.join(":"), href]
                      end.flatten]
      xml = Builder::XmlMarkup.new
      xml.__send__(WRAP_ELEMENT, ns_attrs) do
        xml << fragment
      end
      xml.target!
    end

    def unwrap_fragment(node)
      if node.name==WRAP_ELEMENT
        node.children.first
      else
        node
      end
    end

    def read_xml(node, ns_stack)
      prefix = node.namespace.prefix if node.namespace
      tag = node.name
      ns_tag = [prefix,tag].compact.join(":")

      attrs = read_attributes(node.attributes)
      attrs = attrs.merge(namespace_attributes(node.namespaces, ns_stack))
      attrs = nil if attrs.empty?

      children = node.children.map do |child|
        if child.text?
          child.text
        else
          begin
            ns_stack.push(node.namespaces)
            read_xml(child, ns_stack)
          ensure
            ns_stack.pop
          end
        end
      end

      [ns_tag, attrs, *children].compact
    end

    def read_attributes(attrs)
      Hash[*attrs.map do |n, attr|
             prefix = attr.namespace.prefix if attr.namespace
             name = attr.name
             ns_name = [prefix,name].compact.join(":")
             [ns_name, attr.value]
           end.flatten]
    end

    def namespace_attributes(namespaces, ns_stack)
      Hash[*namespaces.map do |prefix,href|
             [prefix, href] if !find_namespace(prefix, ns_stack)
           end.compact.flatten]
    end

    def find_namespace(prefix, ns_stack)
      ns_stack.reverse.find{ |nsh| nsh.has_key?(prefix)}
    end
  end
end
