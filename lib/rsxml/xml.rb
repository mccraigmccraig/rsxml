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

    def explode_node(node)
      node_name = node.name
      if node.namespace
        node_prefix = node.namespace.prefix || "" # nokogiri has nil prefix for default namespace
        node_uri = node.namespace.href
      end
      node = node_uri ? [node_name, node_prefix, node_uri] : node_name
    end

    # given a <tt>Nokogiri::XML::Element</tt> in +element+ , produce
    # a <tt>[[local_name, prefix, namespace], {[local_name, prefix, namespace]=>value}</tt>
    # pair of exploded element name and attributes with exploded names
    def explode_element(element)
      eelement = explode_node(element)

      eattrs = Hash[element.attributes.map do |name,attr|
                      [explode_node(attr), attr.value]
                    end]

      [eelement, eattrs]
    end

    class ConstructRsxmlVisitor
      attr_reader :sexp
      attr_reader :cursor_stack 

      def initialize()
        @cursor_stack = []
        @sexp
      end

      def tag(context, tag, attrs)
        if attrs.size>0
          el = [tag, attrs]
        else
          el = [tag]
        end

        if !cursor_stack.last
          @sexp = el
        else
          cursor_stack.last << el
        end
        cursor_stack.push(el)

        begin
          yield
        ensure
          cursor_stack.pop
        end
      end

      def text(context, text)
        cursor_stack.last << text
      end
    end

    # pre-order traversal of the Nokogiri Nodes, calling methods on
    # the visitor with each Node
    def traverse(element, visitor, context = Visitor::Context.new)
      eelement, eattrs = explode_element(element)

      ns_bindings = Rsxml::Namespace.extract_declared_namespace_bindings(element.namespaces)
      context.ns_stack.push(ns_bindings)

      begin
        visitor.tag(context, eelement, eattrs) do
          context.push_node([eelement, eattrs])
          begin
            element.children.each do |child|
              if child.element?
                traverse(child, visitor, context)
              elsif child.text?
                visitor.text(context, child)
                context.processed_node(child)
              else
                Rsxml.log{|logger| logger.warn("unknown Nokogiri Node type: #{child.inspect}")}
              end
            end
          ensure
            context.pop_node
          end
        end
      ensure
        context.ns_stack.pop
      end

      visitor
    end

    # def read_xml(element)
    #   traverse(element, ConstructRsxmlVisitor).sexp
    # end

    def read_xml(node, ns_stack=[])
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
