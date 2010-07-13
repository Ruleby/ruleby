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

      rules = Ruleby::Ferrari.parse_containers(args, Ruleby::Ferrari::RulesContainer.new).build(name,options,@engine,&block)
      rules
    end

    def m
      Ruleby::Ferrari::MethodBuilder.new
    end

    def method
      m
    end

    def b(variable_name)
      Ruleby::Ferrari::BindingBuilder.new(variable_name)
    end

    def binding(variable_name)
      b variable_name
    end

    def c(&block)
      return lambda(&block)
    end

    def condition(&block)
      return lambda(&block)
    end

    def OR(*args)
      Ruleby::Ferrari::OrBuilder.new args
    end

    def AND(*args)
      Ruleby::Ferrari::AndBuilder.new args
    end

    def __eval__(x)
      eval(x)
    end
    
   end
end