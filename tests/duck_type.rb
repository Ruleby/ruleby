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

module Duck
  class Foobar
  end
  
  class Email < Message
  end
  
  class Loan
    def initialize(name,age)
      @name = name
      @age = age
      @status = :HELLO
    end
    attr :name, true
    attr :age, true
    attr :status, true
  end
  
  
  class DuckRulebook < Rulebook
  
    def rules  
  
      rule [m.status == :HELLO], [Context, :c] do |v|
        v[:c].inc :rule1
      end
      
      rule [:is_a?, Message, m.status == :HELLO], [Context, :c] do |v|
        v[:c].inc :rule2
      end
      
      rule [Message, m.status == :HELLO], [Context, :c] do |v|
        v[:c].inc :rule3
      end
    end
  end
  
  class DuckTypeTest < Test::Unit::TestCase
  
    def test_0
  
      engine :engine do |e|
        DuckRulebook.new(e).rules
        ctx = Context.new
        a = Loan.new('A','B')
        b = Message.new(:HELLO, 'test')
        c = Email.new(:HELLO, 'test')
        d = Message.new(:FOOBAR, 'foobar')
        f = Foobar.new
        
        e.assert ctx
        e.assert a; e.match; e.retract a
        e.assert b; e.match; e.retract b
        e.assert c; e.match; e.retract c
        e.assert d; e.match; e.retract d
        e.assert f; e.match; e.retract f
       
        assert_equal 3, ctx.get(:rule1)
        assert_equal 2, ctx.get(:rule2)
        assert_equal 1, ctx.get(:rule3)
      end
    end
  end
end