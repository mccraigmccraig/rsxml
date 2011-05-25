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

    # give a list of <tt>Nokogiri::XML::Namespace</tt> definitions, produce
    # a Hash <tt>{prefix=>uri}</tt> of namespace bindings
    def namespace_bindings_from_defs(ns_defs)
      (ns_defs||[]).reduce({}) do |h,ns_def|
        h[ns_def.prefix||""] = ns_def.href
        h
      end
    end

    # pre-order traversal of the Nokogiri Nodes, calling methods on
    # the visitor with each Node
    def traverse(element, visitor, context = Visitor::Context.new)
      ns_bindings = namespace_bindings_from_defs(element.namespace_definitions)
      context.ns_stack.push(ns_bindings)

      eelement, eattrs = explode_element(element)

      begin
        visitor.element(context, eelement, eattrs, ns_bindings) do
          context.push_node([eelement, eattrs, ns_bindings])
          begin
            element.children.each do |child|
              if child.element?
                traverse(child, visitor, context)
              elsif child.text?
                visitor.text(context, child.content)
                context.processed_node(child.content)
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

  end
end
