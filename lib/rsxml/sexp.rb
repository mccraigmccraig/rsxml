module Rsxml
  module Sexp
    class << self
      include Namespace
    end

    module_function

    def write_xml(xml, sexp, ns_stack=[], path=[""], &transformer)
      tag, attrs, children = decompose_sexp(sexp)
      
      ns_declared = extract_declared_namespace_bindings(attrs)

      ns_stack_decl = ns_stack + [ns_declared]
      utag = explode_qname(ns_stack_decl, tag)
      uattrs = explode_attr_qnames(ns_stack_decl, attrs)

      ns_explicit = extract_explicit_namespace_bindings(utag, uattrs)
      ns_undeclared = undeclared_namespaces(ns_stack_decl, ns_explicit)
      ns_undeclared_decls = unqualified_namespace_declarations(ns_undeclared)
      uattrs = uattrs.merge(ns_undeclared_decls)

      ns_new_context = merge_namespace_bindings(ns_declared, ns_undeclared)


      if transformer
        txtag, txattrs = transformer.call(utag, uattrs, path.join("/"))
        raise "transformer returned nil tag from \ntag: #{tag.inspect}\nattrs: #{attrs.inspect}>\npath: #{path.inspect}" if !txtag
      else
        txtag, txattrs = [utag, uattrs]
      end
      
      # figure out which explicit namespaces need declaring

      ns_stack.push(ns_new_context)
      begin

        qname = compact_qname(ns_stack, txtag)
        qattrs = compact_attr_qnames(ns_stack, txattrs)
        xml.__send__(qname, qattrs) do
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
      ensure
        ns_stack.pop
      end
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
