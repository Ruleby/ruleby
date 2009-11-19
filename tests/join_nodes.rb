# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2009 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner
#

require 'test/unit'

require 'ruleby'

include Ruleby

module JoinNodes
  
  class A
    
  end
  
  class B
    
  end

  class JoinNodesRulebook < Rulebook
    def rules        
      rule [A], [B], [Context, :c] do |v|
        v[:c].inc :rule1
      end
    end
  end
    
  class Test < Test::Unit::TestCase  
    def test_0  
      engine :engine do |e|
        JoinNodesRulebook.new(e).rules
        ctx = Context.new
        a = A.new
        b = B.new
        e.assert ctx
        e.assert a
        e.assert b
        e.match          
        assert_equal 1, ctx.get(:rule1)
        e.retract a
        e.match          
        assert_equal 1, ctx.get(:rule1)
        e.assert B.new
        e.match          
        assert_equal 1, ctx.get(:rule1)
        e.assert A.new
        e.match          
        assert_equal 3, ctx.get(:rule1)
        e.retract b
        e.match          
        assert_equal 4, ctx.get(:rule1)
      end
    end
  end
end