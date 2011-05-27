module Rsxml
  module Visitor
    # a mock visitor which can be used to check expectations
    class MockVisitor
      attr_reader :expectations
      
      def initialize(expectations)
        @expectations = expectations.clone
      end

      def __format_invocation__(method, args)
        "#{method}(#{(args||[]).map(&:inspect).join(', ')})"
      end

      def __check_arg_expectation__(arg_xp, arg)
        return true if arg_xp == :_
        return arg_xp.call(arg) if arg_xp.is_a?(Proc)
        return arg_xp == arg
      end

      def __check_expectation__(method, args)
        xp_method, *xp_args = expectations.shift
        msg = "unexpected invocation: #{__format_invocation__(method, args)}. expected: #{__format_invocation__(xp_method, xp_args)}"
        raise msg if method!=xp_method || args.length != xp_args.length
        (0...xp_args.length).each do |i|
          raise msg if !__check_arg_expectation__(xp_args[i], args[i])
        end
      end

      def __finalize__
        raise "missing invocations: #{expectations.map{|xp_method, *xp_args| __format_invocation__(xp_method, xp_args)}.join('\n')}" if expectations && expectations.length>0
      end

      # check that there is an expectation for the invoked method, and if 
      # a block is given yield to that block
      def method_missing(method, *args, &block)
        __check_expectation__(method, args)
        block.call if block
      end

    end
  end
end
