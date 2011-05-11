module Rsxml
  module Visitor
    class << self
      include Util
    end

    class Context
      attr_reader :ns_stack
      attr_reader :node_stack
      attr_reader :prev_siblings
      def initialize(initial_ns_bindings = nil)
        @ns_stack=[]
        @ns_stack << initial_ns_bindings if initial_ns_bindings
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

    class BuildRsxmlVisitor
      attr_reader :sexp
      attr_reader :cursor_stack 
      attr_reader :opts

      # The <tt>:style</tt> option specifies how the Rsxml is to be produced
      #  :xml style is with compact <tt>"prefix:local_name"</tt> Strings for QNames, and namespace declaration attributes
      #  :exploded style is with <tt>[local_name, prefix, uri]</tt> triples for QNames, and no namespace declaration attributes
      OPTS = {:style=>[:xml, :exploded]}

      def initialize(opts=nil)
        @opts = opts || {}
        opts = Util.check_opts(OPTS, opts)
        @cursor_stack = []
        @sexp
      end

      def compact_qname(qname)
        local_name, prefix, uri = qname

        [prefix, local_name].map{|s| (!s || s.empty?) ? nil : s}.compact.join(":")
      end

      def compact_attr_names(attrs)
        Hash[attrs.map{|qname,value| [compact_qname(qname), value]}]
      end

      # strip namespace decls from exploded attributes
      def strip_namespace_decls(attrs)
        Hash[attrs.map do |qname,value| 
               local_name, prefix, uri = qname
               if !(prefix=="xmlns" || (prefix==nil && local_name=="xmlns"))
                 [qname,value]
               end
             end.compact]
      end

      def tag(context, tag, attrs)

        opts[:style] ||= :exploded
        if opts[:style] == :xml
          tag = compact_qname(tag)
          attrs = compact_attr_names(attrs)
        elsif opts[:style] == :exploded
          attrs = strip_namespace_decls(attrs)
        end
        
        el = [tag, (attrs if attrs.size>0)].compact

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



  end
end
