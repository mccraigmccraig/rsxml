module Rsxml
  module Sexp

    module_function

    # pre-order traversal of the sexp, calling methods on
    # the visitor with each node
    def traverse(sexp, visitor, context=Visitor::Context.new)
      element_name, attrs, children = decompose_sexp(sexp)
      
      non_ns_attrs, ns_bindings = Namespace::non_ns_attrs_ns_bindings(context.ns_stack, element_name, attrs)

      context.ns_stack.push(ns_bindings)

      eelement_name = Namespace::explode_qname(context.ns_stack, element_name)
      eattrs = Namespace::explode_attr_qnames(context.ns_stack, non_ns_attrs)

      begin
        visitor.element(context, eelement_name, eattrs, ns_bindings) do
          children.each_with_index do |child, i|
            if child.is_a?(Array)
              traverse(child, visitor, context)
            else
              visitor.text(context, child)
            end
          end
        end
      ensure
        context.ns_stack.pop
      end

      visitor
    end

    # decompose a sexp to a [element_name, attrs, children] list
    def decompose_sexp(sexp)
      raise "invalid rsxml: #{rsxml.inspect}" if sexp.length<1
      if sexp[0].is_a?(Array)
        element_name = sexp[0]
      else
        element_name = sexp[0].to_s
      end
      if sexp[1].is_a?(Hash)
        attrs = sexp[1]
        children = sexp[2..-1]
      else
        attrs = {}
        children = sexp[1..-1]
      end
      [element_name, attrs, children]
    end

    class ComparisonError < RuntimeError
      attr_reader :path
      def initialize(msg, path)
        super("[#{path}]: #{msg}")
        @path = path
      end
    end

    def compare(sexpa, sexpb, path=nil)
      element_name_a, attrsa, childrena = decompose_sexp(sexpa)
      element_name_b, attrsb, childrenb = decompose_sexp(sexpb)

      raise ComparisonError.new("element names differ: '#{element_name_a}', '#{element_name_b}'", path) if element_name_a != element_name_b
      raise ComparisonError.new("attributes differ", path) if attrsa != attrsb
      raise ComparisonError.new("child count differs", path) if childrena.length != childrenb.length

      path = [path, element_name_a].compact.join("/")
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
