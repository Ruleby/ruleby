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
      rule 'For each Message as :m where #message as :x #&& #status == #:x',
           'For each Context as :c' do |v|
        v[:c].inc :rule1
      end
      
      rule [Message, :m, {m.message => :x}, m.status == b(:x)],
           [Context, :c] do |v|
        v[:c].inc :rule2
      end   
      
      # NOTE references the self class binding is not allowed yet
      
  #    rule 'LeTigreTest',
  #      'exists? Message as :m where #status == #:m.message' do |r,v|
  #        puts 'Success'
  #    end
  
  #    rule 'LeTigreTest',
  #      [Message, :m, m.status(:m, &c{|s,m| s == m.message})] do |r,v|
  #        puts 'Success'
  #    end
      
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
        
        assert_equal 1, ctx.get(:rule1)
        assert_equal 1, ctx.get(:rule2)
      end
    end
  end
end