module Rsxml
  module Util
    module_function
    
    def check_opts(constraints, opts)
      (opts||{}).each do |k,v|
        raise "opt not permitted: #{k}" if !constraints.has_key?(k)
        constraint = constraints[k]
      end
    end
  end
end
