module Rsxml
  module Util
    module_function
    
    # simple option checking, with value constraints, sub-hashes and defaulting
    def check_opts(constraints, opts)
      opts.each{|k,v| raise "opt not permitted: '#{k}'" if !constraints.has_key?(k)}
      Hash[constraints.map do |k,constraint|
             v = opts[k]
             if constraint.is_a?(Array)
               raise "unknown value for opt '#{k}': '#{v}'. permitted values are: #{constraint.inspect}"
               [k,v]
             elsif constraint.is_a?(Hash)
               if v
                 raise "opt '#{k}' must be a Hash" if !v.is_a?(Hash)
                 [k,check_opts(constraint, v || {})]
               end
             elsif !v && !constraint.nil?
               [k,constraint]
             else
               [k,v]
             end
           end]
    end
  end
end
