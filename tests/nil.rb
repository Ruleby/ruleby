# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2010 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner, Matt Smith
#

require 'test/unit'
require 'ruleby'

include Ruleby

module Nil
  
  class Number
    def initialize(value)
       @value = value
     end
     attr:value, true
  end
  
  class NilRulebook < Rulebook
    def rules        
      rule [Number, :m, m.value == 42], [Context, :c] do |v|
        v[:c].inc :rule1
      end  
      
      rule [Number, :m, m.value < 42], [Context, :c] do |v|
        v[:c].inc :rule2
      end   
      
      rule [Number, :m, m.value > 42], [Context, :c] do |v|
        v[:c].inc :rule3
      end
      
      rule [Number, :m, m.value <= 42], [Context, :c] do |v|
        v[:c].inc :rule4
      end
      
      rule [Number, :m, m.value >= 42], [Context, :c] do |v|
        v[:c].inc :rule5
      end
    end
  end
  
  class Test < Test::Unit::TestCase
  
    def test_0
      
      engine :engine do |e|
        NilRulebook.new(e).rules
        
        ctx = Context.new
        e.assert ctx
        e.assert Number.new(43)
        e.assert Number.new(42)
        e.assert Number.new(41)
        e.match
        
        assert_equal 1, ctx.get(:rule1)
        assert_equal 1, ctx.get(:rule3)
        assert_equal 1, ctx.get(:rule2)
        assert_equal 2, ctx.get(:rule4)
        assert_equal 2, ctx.get(:rule5)
      end
    end
  end
end