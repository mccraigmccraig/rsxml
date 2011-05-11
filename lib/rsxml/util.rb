module Rsxml
  module Util
    module_function
    
    # simple option checking, with value constraints and sub-hash checking
    def check_opts(constraints, opts)
      opts ||= {}
      opts.each{|k,v| raise "opt not permitted: #{k.inspect}" if !constraints.has_key?(k)}
      Hash[constraints.map do |k,constraint|
             if opts.has_key?(k)
               v = opts[k]
               if constraint.is_a?(Array)
                 raise "unknown value for opt #{k.inspect}: #{v.inspect}. permitted values are: #{constraint.inspect}" if !constraint.include?(v)
                 [k,v]
               elsif constraint.is_a?(Hash)
                 raise "opt #{k.inspect} must be a Hash" if !v.is_a?(Hash)
                 [k,check_opts(constraint, v || {})]
               else
                 [k,v]
               end
             end
           end]
    end
  end
end
