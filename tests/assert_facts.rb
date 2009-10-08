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

module AssertFacts

  class Fibonacci
    def initialize(sequence,value=-1)
      @sequence = sequence
      @value = value 
    end

    attr_reader :sequence  
    attr :value, true

    def to_s
      return super + "::sequence=" + @sequence.to_s + ",value=" + @value.to_s
    end
  end
  
  class SimpleRulebook < Rulebook
    def rules          
      rule [Message, :m, {m.message => :x}, m.status == b(:x)],
           [Context, :c] do |v|
        v[:c].inc :rule1
      end   
    end
  end
  
  class FibonacciRulebook < Rulebook
    def rules
     # Bootstrap1
      rule  :Bootstrap1,  {:priority => 4},
        [Fibonacci, :f, m.value == -1, m.sequence == 1 ] do |vars|  
          vars[:f].value = 1
          modify vars[:f]     
      end  

      # Recurse
      rule :Recurse, {:priority => 3},
        [Fibonacci, :f, m.value == -1] do |vars|   
          f2 = Fibonacci.new(vars[:f].sequence - 1)
          assert f2
      end  

      # Bootstrap2
      rule :Bootstrap2, 
        [Fibonacci, :f, m.value == -1 , m.sequence == 2] do |vars|    
          vars[:f].value = 1       
          modify vars[:f]
      end

      # Calculate
      rule :Calculate,
        [Context, :c],
        [Fibonacci,:f1, m.value.not== -1, {m.sequence => :s1}],
        [Fibonacci,:f2, m.value.not== -1, {m.sequence( :s1, &c{ |s2,s1| s2 == s1 + 1 } ) => :s2}],
        [Fibonacci,:f3, m.value == -1, m.sequence(:s2, &c{ |s3,s2| s3 == s2 + 1 }) ] do |vars|
          vars[:f3].value = vars[:f1].value + vars[:f2].value
          modify vars[:f3]
          retract vars[:f1]
          vars[:c].set vars[:f3].sequence, vars[:f3].value
      end
    end
  end
  
  class Test < Test::Unit::TestCase
  
    def test_0  
      engine :engine do |e|
        ctx = Context.new
        e.assert ctx
        e.assert Message.new(:HELLO, :HELLO)
        SimpleRulebook.new(e).rules
        e.assert Message.new(:HELLO, :GOODBYE)
        e.match          
        assert_equal 1, ctx.get(:rule1)
      end
    end
    
    def test_1  
      engine :engine do |e|
        ctx = Context.new
        e.assert ctx
        e.assert Message.new(:HELLO, :HELLO)
        e.assert Message.new(:HELLO, :GOODBYE)
        SimpleRulebook.new(e).rules
        e.match          
        assert_equal 1, ctx.get(:rule1)
      end
    end
    
    def test_2
      fib1 = Fibonacci.new(150)
      engine :engine do |e|
        FibonacciRulebook.new(e).rules
        ctx = Context.new
        e.assert ctx
        e.assert fib1
        e.match   
        assert_equal 9969216677189303386214405760200, ctx.get(150)
      end
    end
    
    def test_3
      fib1 = Fibonacci.new(150)
      engine :engine do |e|
        ctx = Context.new
        e.assert ctx
        e.assert fib1
        FibonacciRulebook.new(e).rules
        e.match   
        assert_equal 9969216677189303386214405760200, ctx.get(150)
      end
    end
  end
end