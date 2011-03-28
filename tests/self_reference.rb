# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2008 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner, Matt Smith, John Mettraux
#

require 'test/unit'

require 'ruleby'

include Ruleby

module SelfReference

  class SelfRefRulebook < Rulebook
    def rules
      rule [Message, :m, {m.message => :x}, m.status == b(:x)],
           [Context, :c] do |v|
        v[:c].inc :rule2
      end

      # This is effectively the same as the rule above
      rule [Message, :m, m.status == m.message],
           [Context, :c] do |v|
        v[:c].inc :rule3
      end
            
    end
  end
  
  
  class Test < Test::Unit::TestCase
  
    def test_0
  
      engine :engine do |e|
        SelfRefRulebook.new(e).rules
        ctx = Context.new
        e.assert ctx
        e.assert Message.new(:HELLO, :HELLO)
        e.assert Message.new(:HELLO, :GOODBYE)
        e.match  
        
        assert_equal 1, ctx.get(:rule2)
        assert_equal 1, ctx.get(:rule3)
      end
    end
  end
end