# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2008 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner
#

require 'test/unit'

require 'ruleby'

include Ruleby

module NotPatterns
  
  class A 
    attr :name, true
  end
  
  class B
    attr :name, true    
  end

  class C
    attr :name, true    
  end

  class NotPatternsRulebook < Rulebook
    def rules        
      rule [:not, A], [Context, :c] do |v|
        v[:c].inc :rule1
      end   
            
      rule [Context, :c], [:not, A, m.name == :X] do |v|
        v[:c].inc :rule2
      end 
      
      rule [:not, A, m.name == :Y], [Context, :c] do |v|
        v[:c].inc :rule3
      end 
            
      rule [A, {m.name => :x}], 
           [:not, B, m.name == b(:x)], 
           [Context, :c] do |v|
        v[:c].inc :rule4
      end

      rule [A, :a, {m.name => :x}], 
           [:not, C, :c, m.name == b(:x)], 
           [Context, :c] do |v|
        v[:c].inc :rule5
      end
      
      rule [:not, Message], [Context, :c] do |v|
        v[:c].inc :rule6
      end
    end
  end
    
  class Test < Test::Unit::TestCase  
    def test_0  
      engine :engine do |e|
        NotPatternsRulebook.new(e).rules
        ctx = Context.new
        e.assert ctx
        
        a = A.new
        a.name = :X
        e.assert a
        b = B.new
        b.name = :Y
        e.assert b
        c = C.new
        c.name = :X        
        e.assert c
        
        e.match          
        assert_equal 0, ctx.get(:rule1)
        assert_equal 1, ctx.get(:rule3)
        assert_equal 0, ctx.get(:rule2)
        assert_equal 1, ctx.get(:rule4)
        assert_equal 0, ctx.get(:rule5)
        assert_equal 1, ctx.get(:rule6)
      end
    end
  end
end