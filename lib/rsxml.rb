require 'nokogiri'
require 'builder'

module Rsxml
  module_function

  # convert an s-expression representation of an XML document to XML
  #  Rsxml.to_xml(["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"] ["Baz"]])
  #   => '<Foo foofoo="10"><Bar>barbar</Bar><Baz></Baz></Foo>' 
  def to_xml(rsxml)
    xml = Builder::XmlMarkup.new
    Sexp.write_xml(xml, rsxml)
    xml.target!
  end

  # convert an XML string to an s-expression representation
  #  Rsxml.to_rsxml('<Foo foofoo="10"><Bar>barbar</Bar><Baz></Baz></Foo>')
  #   => ["Foo", {"foofoo"=>"10"}, ["Bar", "barbar"], ["Baz"]] 
  def to_rsxml(doc)
    root = Nokogiri::XML(doc).children.first
    Xml.read_xml(root, [])
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
  end

  module Xml
    module_function

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
