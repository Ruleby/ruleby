# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Matt Smith, Joe Kutner
#

require 'ruleby'
require 'dsl/ferrari'
require 'dsl/letigre'
require 'dsl/steel'

module Ruleby
  class Rulebook
    include Ruleby
    def initialize(engine, session={})
      @engine = engine
      @session = session
    end
  
    attr_reader :engine
    attr_reader :session
    
    def assert(fact)
      @engine.assert fact
    end
    def retract(fact)
      @engine.retract fact
    end
    def modify(fact)
      @engine.modify fact
    end
    def rule(*args, &block)
      unless args.empty?
        name = args[0].kind_of?(Symbol) ? args.shift : GeneratedTag.new
      end
    
      if args.empty?
        # use steel DSL
        r = Steel::RulebookHelper.new @engine
        r.rule name, &block
      else
        i = args[0].kind_of?(Hash) ? 1 : 0
        if args[i].kind_of? Array
          # use ferrari DSL
          r = Ferrari::RulebookHelper.new @engine
          r.rule name, *args, &block
        elsif args[i].kind_of? String
          # use letigre DSL
          r = LeTigre::RulebookHelper.new @engine, self
          r.rule name, *args, &block
        else
          raise 'Rule format not recognized.'
        end
      end
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
      b
    end
    
    def c(&block)
      return lambda(&block)
    end
    
    def condition(&block)
      return lambda(&block)
    end
    
    def __eval__(x)
      eval(x)
    end
  end  
  
  class GeneratedTag  
    # this counter is incremented for each UniqueTag created, and is
    # appended to the end of the unique_seed in order to create a 
    # string that is unique for each instance of this class.
    @@tag_counter = 0
    
    # every generated tag will be prefixed with this string
    @@unique_seed = 'unique_seed'
  
    def initialize()
      @@tag_counter += 1
      @tag = @@unique_seed + @@tag_counter.to_s
    end
    
    attr_reader:tag_counter
    attr_reader:unique_seed
    attr_reader:tag
    
    def ==(ut)
      return ut && ut.kind_of?(GeneratedTag) && @tag == ut.tag
    end
    
    def to_s
      return @tag.to_s
    end
  end
end