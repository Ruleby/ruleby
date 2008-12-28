
module Ruleby
    class TreetopHelper
      
      def self.rule(name, *args, &block) 
        options = args[0].kind_of?(Hash) ? args.shift : {}        
  
        r = Ferrari::RuleBuilder.new name
        args.each do |arg|
          if arg.kind_of? Array
            r.when(*arg)
          else
            raise 'Invalid condition.  All or none must be Arrays.'
          end
        end
  
        r.then(&block)
        r.priority = options[:priority] if options[:priority]
  
        return r.build_rule
      end
    end
end