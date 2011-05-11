module Rsxml
  module Visitor
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



  end
end
