module Rsxml
  module Sexp
    class Context
      attr_reader :ns_stack
      attr_reader :node_stack
      attr_reader :prev_siblings
      def initialize()
        @ns_stack=[]
        @node_stack=[]
        @prev_siblings=[]
        @sibling_stack=[]
      end

      def push_node(node)
        node_stack.push(node)
        @sibling_stack.push(@prev_siblings)
        @prev_siblings=[]
      end

      def pop_node
        n = node_stack.pop
        @prev_siblings = @sibling_stack.pop
        @prev_siblings << n
      end

      def processed_node(node)
        @prev_siblings << node
      end
    end

    class WriteXmlVisitor
      attr_reader :xml
      def initialize(xml_builder=nil)
        @xml = xml_builder || Builder::XmlMarkup.new
      end

      def tag(context, name, attrs)
        qname = Namespace::compact_qname(context.ns_stack, name)
        qattrs = Namespace::compact_attr_qnames(context.ns_stack, attrs)

        xml.__send__(qname, qattrs) do
          yield
        end
      end

      def text(context, text)
        xml << text
      end

      def to_s
        xml.target!
      end
    end

    module_function

    def traverse(sexp, visitor, context=Context.new)
      tag, attrs, children = decompose_sexp(sexp)
      
      # create ns bindings for explicit namespaces which need them
      ns_declared = Namespace::extract_declared_namespace_bindings(attrs)
      ns_explicit = Namespace::extract_explicit_namespace_bindings(tag, attrs)
      ns_undeclared = Namespace::undeclared_namespace_bindings(context.ns_stack + [ns_declared], ns_explicit)
      ns_new_bindings = Namespace::merge_namespace_bindings(ns_declared, ns_undeclared)

      # and declarations for undeclared namespaces
      ns_undeclared_decls = Namespace::exploded_namespace_declarations(ns_undeclared)

      context.ns_stack.push(ns_new_bindings)

      etag = Namespace::explode_qname(context.ns_stack, tag)
      eattrs = Namespace::explode_attr_qnames(context.ns_stack, attrs)

      eattrs = eattrs.merge(ns_undeclared_decls)

      begin
        visitor.tag(context, etag, eattrs) do
          begin
          context.push_node([etag, eattrs])
            children.each_with_index do |child, i|
              if child.is_a?(Array)
                traverse(child, visitor, context)
              else
                visitor.text(context, child)
                context.processed_node(child)
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

    def decompose_sexp(sexp)
      raise "invalid rsxml: #{rsxml.inspect}" if sexp.length<1
      if sexp[0].is_a?(Array)
        tag = sexp[0]
      else
        tag = sexp[0].to_s
      end
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

end
