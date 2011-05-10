module Rsxml
  module Sexp
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

    # namespace qualify attrs
    def compact_attr_qnames(ns_stack, attrs)
      Hash[attrs.map do |name,value|
             [compact_qname(ns_stack, name), value]
           end]
    end

    def explode_attr_qnames(ns_stack, attrs)
      Hash[attrs.map do |name, value|
             uq_name = explode_qname(ns_stack, name, true)
             local_name, prefix, uri = uq_name
             if !prefix || prefix==""
               [local_name, value]
             else
               [uq_name, value]
             end
           end]
    end

    # produce a QName from a [LocalPart, prefix, URI] triple
    def compact_qname(ns_stack, name)
      return name if name.is_a?(String)

      local_part, prefix, uri = name
      raise "invalid name: #{name}" if !prefix && uri
      if prefix
        if prefix!="xmlns"
          ns = find_namespace_uri(ns_stack, prefix, uri)
          raise "namespace prefix not bound to a namespace: '#{prefix}'" if ! ns
        end
        [prefix, local_part].map{|s| s.to_s unless s.to_s.empty?}.compact.join(':')
      else
        local_part
      end
    end

    # split a QName into [LocalPart, prefix and URI] triple
    def explode_qname(ns_stack, qname, attr=false)
      if qname.is_a?(Array)
        if qname.length>1 && !qname[1].nil?
          return qname
        elsif qname.length>1 && qname[1].nil? && !qname[2].nil?
          raise "invalid name: #{qname.inspect}"
        else
          return qname[0]
        end
      end

      local_part, prefix = split_qname(qname)
      if prefix
        if prefix=="xmlns" && attr
          [local_part, prefix]
        else
          uri = find_namespace_uri(ns_stack, prefix)
          raise "namespace prefix not bound: '#{prefix}'" if ! uri
          [local_part, prefix, uri]
        end
      else
        if attr
          local_part
        else
          default_uri = find_namespace_uri(ns_stack, "")
          if default_uri
            [local_part, "", default_uri]
          else
            local_part
          end
        end
      end
    end

    # split a qname String into a [local_part, prefix] pair
    def split_qname(qname)
      return qname if qname.is_a?(Array)

      if qname =~ /^[^:]+:[^:]+$/
        [*qname.split(':')].reverse
      else
        qname
      end
    end

    # returns the namespace uri for a prefix, if declared in the stack
    def find_namespace_uri(ns_stack, prefix, uri_check=nil)
      tns = ns_stack.reverse.find{|ns| ns.has_key?(prefix)}
      uri = tns[prefix] if tns
      raise "prefix: '#{prefix}' is bound to uri: '#{uri}', but should be '#{uri_check}'" if uri_check && uri && uri!=uri_check
      uri
    end


    # extract a Hash of {prefix=>uri} mappings declared in attributes
    def extract_declared_namespace_bindings(attrs)
      Hash[attrs.map do |name,value|
             local_part, prefix, uri = split_qname(name)
             if (prefix && prefix == "xmlns")
               [local_part, value]
             elsif (!prefix && local_part == "xmlns")
               ["", value]
             end
           end.compact]
    end

    # extract a Hash of {prefix=>uri} mappings from expanded tags
    def extract_explicit_namespace_bindings(tag, attrs)
      tag_local_part, tag_prefix, tag_uri = tag
      ns = {}
      ns[tag_prefix] = tag_uri if tag_prefix && tag_uri

      attrs.each do |name, value|
        attr_local_part, attr_prefix, attr_uri = name
        if attr_prefix && attr_uri
          raise "bindings clash: '#{attr_prefix}'=>'#{ns[attr_prefix]}' , '#{attr_prefix}'=>'#{attr_uri}'" if ns.has_key?(attr_prefix) && ns[attr_prefix]!=attr_uri
          ns[attr_prefix] = attr_uri
        end
      end
      ns
    end
    
    # figure out which explicit namespaces need declaring
    #
    # +ns_stack+ is the stack of namespace bindings
    # +ns_explicit+ is the explicit refs for a tag
    def undeclared_namespaces(ns_stack, ns_explicit)
      Hash[ns_explicit.map do |prefix,uri|
             [prefix, uri] if !find_namespace_uri(ns_stack, prefix, uri)
           end.compact]
    end

    # produce a Hash of namespace declaration attributes from 
    # a Hash of namespace prefix bindings
    def unqualified_namespace_declarations(ns)
      Hash[ns.map do |prefix, uri|
             if prefix==""
               ["xmlns", uri]
             else
               [[prefix, "xmlns"], uri]
             end
           end]
    end

    # merges two sets of namespace bindings, raising error on clash
    def merge_namespace_bindings(ns1, ns2)
      m = ns1.clone
      ns2.each do |k,v|
        raise "bindings clash: '#{k}'=>'#{m[k]}' , '#{k}'=>'#{v}'" if m.has_key?(k) && m[k]!=v
        m[k]=v
      end
      m
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
