module Rsxml
  module Namespace
    module_function
    
    # compact all attribute QNames to Strings
    def compact_attr_qnames(ns_stack, attrs)
      Hash[attrs.map do |name,value|
             [compact_qname(ns_stack, name), value]
           end]
    end

    # explode attribute QNames to [LocalPart, prefix, URI] triples,
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

    # produce a QName String from a [LocalPart, prefix, URI] triple
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

    # split a QName into [LocalPart, prefix, URI] triple
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

    # split attributes into non-namespace related attrs and {prefix=>uri} namespace bindings
    def partition_namespace_decls(attrs)
      nonns_attrs = []
      ns_bindings = []
      attrs.each do |name, value| 
        local_part, prefix = split_qname(name)
        if prefix && prefix=="xmlns"
          ns_bindings << [local_part, value]
        elsif !prefix && local_part=="xmlns"
          ns_bindings << ["", value]
        else
          nonns_attrs << [name, value]
        end
      end
      [Hash[nonns_attrs], Hash[ns_bindings]]
    end

    # extract a Hash of {prefix=>uri} mappings from exploded QName tag and attrs
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
    def undeclared_namespace_bindings(ns_stack, ns_explicit)
      Hash[ns_explicit.map do |prefix,uri|
             [prefix, uri] if !find_namespace_uri(ns_stack, prefix, uri)
           end.compact]
    end

    # produce a Hash of namespace declaration attributes with exploded
    # QNames, from 
    # a Hash of namespace prefix bindings
    def exploded_namespace_declarations(ns)
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

    # given the existing +ns_stack+ of ns bindings, a +tag+ and it's +attributes+,
    # return a pair <tt>[non_ns_attrs, ns_bindings]</tt> containing
    # non-ns related attributes, and namespace bindings for the current element,
    # both those declared in attributes and declared implicitly through exploded tags
    def non_ns_attrs_ns_bindings(ns_stack, tag, attrs)
      non_ns_attrs, ns_declared = partition_namespace_decls(attrs)

      ns_explicit = extract_explicit_namespace_bindings(tag, attrs)
      ns_undeclared = undeclared_namespace_bindings(ns_stack + [ns_declared], ns_explicit)
      ns_bindings = merge_namespace_bindings(ns_declared, ns_undeclared)

      [non_ns_attrs, ns_bindings]
    end

  end
end
