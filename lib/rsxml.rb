require 'nokogiri'
require 'builder'

module Rsxml
  module_function

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
    xml = Builder::XmlMarkup.new
    Sexp.write_xml(xml, rsxml, &transformer)
    xml.target!
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

    def write_xml(xml, sexp, ns_stack=[], path=[""], &transformer)
      tag, attrs, children = decompose_sexp(sexp)
      
      if transformer
        txtag, txattrs = transformer.call(tag, attrs, path.join("/"))
        raise "transformer returned nil tag from \ntag: #{tag.inspect}\nattrs: #{attrs.inspect}>\npath: #{path.inspect}" if !txtag
      else
        txtag, txattrs = [tag, attrs]
      end
      
      xml.__send__(txtag, txattrs) do
        children.each_with_index do |child, i|
          begin
            path.push("#{tag}[#{i}]")
            if child.is_a?(Array)
              write_xml(xml, child, ns_stack, path, &transformer)
            else
              xml << child
            end
          ensure
            path.pop
          end
        end
      end
    end

    # namespace qualify attrs
    def qualify_attrs(ns_stack, attrs)
      Hash[*attrs.map do |name,value|
             [qualify_name(ns_stack, name), value]
           end.flatten]
    end

    # namespace qualify a name: turns a LocalPart into a QName
    def qualify_name(ns_stack, name)
      local_part, prefix, uri = name

      if prefix
        ns = find_namespace(ns_stack, prefix)
        raise "namespace prefix not bound to a namespace: #{name[1]}" if ! ns
        "#{prefix}:#{local_part}"
      else
        local_part
      end
    end

    # split a qname into [LocalPart, prefix and uri]
    def unqualify_name(ns_stack, qname)
      
    end



    NS_ATTR_P = /^xmlns(?:$|\:.+)/
    NS_ATTR_PREFIX = /^xmlns:?(.*)/

    # extract a Hash of {prefix=>uri} mappings declared in attributes
    def extract_namespaces(attrs)
      Hash[*attrs.map do |name,value|
             if name =~ NS_ATTR_P
               prefix = name[ NS_ATTR_PREFIX , 1]
               [prefix, value]
             end
           end.compact.flatten]
    end

    # extract a Hash of {prefix=>uri} mappings
    def extract_undeclared_namespaces(tag, attrs)
      tag_local_part, tag_prefix, tag_uri = tag
      ns = {}
      ns[tag_prefix] = tag_uri if tag_prefix && tag_uri

      attrs.each do |name, value|
        next unless name =~ NS_ATTR_P
        attr_local_part, attr_prefix, attr_uri = name
        ns[attr_prefix] = attr_uri if attr_prefix && attr_uri
      end
    end

    # returns the namespace uri for a prefix, if declared in the stack
    def find_namespace(ns_stack, prefix)
      tns = ns_stack.reverse.find{|ns| ns.has_key?(prefix)}
      tns[prefix] if tns
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

      ns_attrs = Hash[ns_prefixes.map do |prefix,href|
                        prefix = nil if prefix.to_s.length == 0
                        [["xmlns", prefix].compact.join(":"), href]
                      end]
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
      Hash[attrs.map do |n, attr|
             prefix = attr.namespace.prefix if attr.namespace
             name = attr.name
             ns_name = [prefix,name].compact.join(":")
             [ns_name, attr.value]
           end]
    end

    def namespace_attributes(namespaces, ns_stack)
      Hash[namespaces.map do |prefix,href|
             [prefix, href] if !find_namespace(prefix, ns_stack)
           end.compact]
    end

    def find_namespace(prefix, ns_stack)
      ns_stack.reverse.find{ |nsh| nsh.has_key?(prefix)}
    end
  end
end
