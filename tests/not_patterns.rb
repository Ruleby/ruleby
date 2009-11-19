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

  class NotPatternsRulebook < Rulebook
    def rules        
      rule [:not, Message], [Context, :c] do |v|
        v[:c].inc :rule1
      end   
            
      rule [Context, :c], [:not, Message, m.message == :HELLO] do |v|
        v[:c].inc :rule2
      end 
      
      rule [:not, Message, m.message == :FOOBAR], [Context, :c] do |v|
        v[:c].inc :rule3
      end
    end
  end
    
  class Test < Test::Unit::TestCase  
    def test_0  
      engine :engine do |e|
        NotPatternsRulebook.new(e).rules
        ctx = Context.new
        e.assert ctx
        e.assert Message.new(:HELLO, :HELLO)
        e.assert Message.new(:HELLO, :GOODBYE)
        e.match          
        assert_equal 1, ctx.get(:rule1)
        assert_equal 1, ctx.get(:rule3)
        # assert_equal 0, ctx.get(:rule2)
      end
    end
  end
end