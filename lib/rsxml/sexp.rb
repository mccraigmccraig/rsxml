module Rsxml
  module Sexp

    module_function

    # pre-order traversal of the sexp, calling methods on
    # the visitor with each node
    def traverse(sexp, visitor, context=Visitor::Context.new)
      tag, attrs, children = decompose_sexp(sexp)
      
      ns_bindings, ns_additional_decls = Namespace::namespace_bindings_declarations(context.ns_stack, tag, attrs)

      context.ns_stack.push(ns_bindings)

      etag = Namespace::explode_qname(context.ns_stack, tag)
      eattrs = Namespace::explode_attr_qnames(context.ns_stack, attrs)

      eattrs = eattrs.merge(ns_additional_decls)

      begin
        visitor.tag(context, etag, eattrs) do
          context.push_node([etag, eattrs])
          begin
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

    # decompose a sexp to a [tag, attrs, children] list
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
      raise ComparisonError.new("child count differs", path) if childrena.length != childrenb.length

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
