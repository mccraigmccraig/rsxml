module Rsxml
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
