# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner, Matt Smith
#

require 'test/unit'
require 'ruleby'

include Ruleby

MY_RE = /slot_(\d+)/

module RE
  
  class RERulebook < Rulebook
    def rules    
      
      rule [Message, :m, m.message =~ MY_RE], [Context, :c] do |v|
        v[:c].inc :my_re
      end   
      
    end
  end
  
  class Test < Test::Unit::TestCase
  
    def test_0
      ctx = Context.new
      
      engine :engine do |e|
        RERulebook.new(e).rules
        e.assert ctx
        e.assert Message.new(:HELLO, 'slot_1')
        e.assert Message.new(:HELLO, 'slot_x')
        e.match  
      end
      
      assert_equal 1, ctx.get(:my_re)
    end
  end
end