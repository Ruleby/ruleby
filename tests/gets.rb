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

TEST_STR = String.new("it worked")

module Get
  
  class GetRulebook < Rulebook
    def rules    
      
      rule [Message, :m, m.status == :HELLO] do |v|
        @engine.assert TEST_STR
      end   
      
    end
  end
  
  class Test < Test::Unit::TestCase
  
    def test_0
      
      engine :engine do |e|
        GetRulebook.new(e).rules
        e.assert Message.new(:HELLO, 'test')
        e.match
        
        strs = e.retrieve(String)
        
        assert_equal 1, strs.size
      
        assert_equal TEST_STR, strs[0]
      end
    end
  end
end