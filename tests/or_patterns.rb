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

module OrPatterns

  class OrPatternsRulebook < Rulebook
    def rules        
      rule OR([Message, m.message == :HELLO], [Message, m.message == :GOODBYE]), [Context, :c] do |v|
        v[:c].inc :rule1
      end  
      # 
      # rule OR([Message, m.message == :HELLO], [Message, m.message == :FOOBAR]), [Context, :c] do |v|
      #   v[:c].inc :rule2
      # end 
      # 
      # rule OR([Message, m.message == :HELLO], [Message, m.message == :HELLO]), [Context, :c] do |v|
      #   # this doesn't work yet, but we need it to.
      #   v[:c].inc :rule3
      # end 
      # 
      # rule OR([Message, m.message == :FOO], [Message, m.message == :BAR]), [Context, :c] do |v|
      #   v[:c].inc :rule4
      # end
      #   
      # rule OR([Message, m.message == :FOOBAR], [Message, m.message == :GOODBYE]), [Context, :c] do |v|
      #   v[:c].inc :rule5
      # end   
      # 
      # rule AND([Message, m.message == :HELLO], [Message, m.message == :GOODBYE]), [Context, :c] do |v|
      #   # no reason for this to work - its verbose, just checking.
      #   v[:c].inc :rule6
      # end   
      # 
      # rule AND([Message, m.message == :FOOBAR], [Message, m.message == :GOODBYE]), [Context, :c] do |v|
      #   # no reason for this to work - its verbose, just checking.
      #   v[:c].inc :rule7
      # end    
      # 
      # rule OR(AND([Message, m.message == :HELLO], [Message, m.message == :GOODBYE])), [Context, :c] do |v|
      #   v[:c].inc :rule8
      # end   
      # 
      # rule OR([Message, m.message == :HELLO]), [Context, :c] do |v|
      #   v[:c].inc :rule9
      # end     
      # 
      # rule OR(AND([Message, m.message == :HELLO], [Message, m.message == :GOODBYE]), [Message, m.message == :FOOBAR]), [Context, :c] do |v|
      #   v[:c].inc :rule10
      # end   
      # 
      # rule AND([Message, m.message == :HELLO], [Context, :c]) do |v|
      #   # no reason for this to work - its verbose.  But it does work, so just checking.
      #   v[:c].inc :rule11
      # end   
      # 
      # rule AND([Message, m.message == :FOOBAR], [Context, :c]) do |v|
      #   # no reason for this to work - its verbose.  But it does work, so just checking.
      #   v[:c].inc :rule12
      # end
      # 
      # rule OR([Message, :f, m.message == :FOOBAR], [Message, :g, m.message == :GOODBYE]), [Context, :c] do |v|
      #   if v[:f]
      #     # :f should be null
      #     v[:c].inc :rule13a          
      #   end
      #   
      #   if v[:g]
      #     # :g should never be null
      #     v[:c].inc :rule13b
      #   end
      # end 
      # 
      # rule OR([[Message, m.message == :HELLO], [Message, m.message == :GOODBYE]]), [Context, :c] do |v|
      #   v[:c].inc :rule14
      # end
      # 
      # rule [[Message, m.message == :FOOBAR], [Context, :c]] do |v|
      #   # this shouldn't work, its just bad syntax
      #   v[:c].inc :rule15
      # end 
      # 
      # rule OR([[Message, m.message == :HELLO], [Message, m.message == :GOODBYE]], OR([Message, m.message == :FOOBAR], [Message, m.message == :THIRD])), [Context, :c] do |v|
      #   v[:c].inc :rule16
      # end
    end
  end
    
  class Test < Test::Unit::TestCase  
    def test_0  
      engine :engine do |e|
        OrPatternsRulebook.new(e).rules
        ctx = Context.new
        e.assert ctx
        e.assert Message.new(:HELLO, :HELLO)
        e.assert Message.new(:HELLO, :GOODBYE)
        e.assert Message.new(:HELLO, :THIRD)
        e.match          
        # assert_equal 1, ctx.get(:rule16) 
        # assert_equal 0, ctx.get(:rule15)
        # assert_equal 1, ctx.get(:rule14)
        # assert_equal 1, ctx.get(:rule13b)
        # assert_equal 0, ctx.get(:rule13a)
        # assert_equal 0, ctx.get(:rule12)
        # assert_equal 1, ctx.get(:rule11)
        # assert_equal 1, ctx.get(:rule10)
        # assert_equal 1, ctx.get(:rule9)
        # assert_equal 1, ctx.get(:rule8)
        # assert_equal 0, ctx.get(:rule7)
        # assert_equal 1, ctx.get(:rule6)
        # assert_equal 1, ctx.get(:rule5)
        # assert_equal 0, ctx.get(:rule4)
        # assert_equal 0, ctx.get(:rule3) # todo should be 1
        # assert_equal 1, ctx.get(:rule2)
        assert_equal 1, ctx.get(:rule1) 
      end
    end
  end
end