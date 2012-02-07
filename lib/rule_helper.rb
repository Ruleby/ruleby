# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors:  Joe Kutner, Matt Smith
#

require 'core/engine'

module Ruleby
  module RuleHelper
    def rule(*args, &block) 
      name = nil
      unless args.empty?
        name = args[0].kind_of?(Symbol) ? args.shift : GeneratedTag.new
      end
      options = args[0].kind_of?(Hash) ? args.shift : {}        

      rules = Ruleby::Magnum.parse_containers(args, Ruleby::Magnum::RulesContainer.new).build(name,options,@engine,&block)
      rules
    end

    def where
      Ruleby::Magnum::WhereBuilder.new(&Proc.new)
    end

    def name(n)

    end

    def OR(*args)
      Ruleby::Magnum::OrBuilder.new args
    end

    def AND(*args)
      Ruleby::Magnum::AndBuilder.new args
    end
    
   end
end