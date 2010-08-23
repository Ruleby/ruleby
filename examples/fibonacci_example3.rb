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

$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib/')
require 'ruleby'
require 'rule_helper'
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

include Ruleby::RuleHelper
#RULES
rules = []
# Bootstrap1
rules += rule  :Bootstrap1,  {:priority => 4},
    [Fibonacci, :f, m.value == -1, m.sequence == 1 ] do |vars, engine|  
      vars[:f].value = 1
      engine.modify vars[:f]
      puts vars[:f].sequence.to_s + ' == ' + vars[:f].value.to_s      
  end  

  # Recurse
rules += rule :Recurse, {:priority => 3},
    [Fibonacci, :f, m.value == -1] do |vars, engine|   
      f2 = Fibonacci.new(vars[:f].sequence - 1)
      engine.assert f2
      puts 'recurse for ' + f2.sequence.to_s
  end  

  # Bootstrap2
rules += rule :Bootstrap2, 
    [Fibonacci, :f, m.value == -1 , m.sequence == 2] do |vars, engine|    
      vars[:f].value = 1       
      engine.modify vars[:f]
      puts vars[:f].sequence.to_s + ' == ' + vars[:f].value.to_s
  end

  # Calculate
rules += rule :Calculate,
    [Fibonacci,:f1, m.value.not== -1, {m.sequence => :s1}],
    [Fibonacci,:f2, m.value.not== -1, {m.sequence( :s1, &c{ |s2,s1| s2 == s1 + 1 } ) => :s2}],
    [Fibonacci,:f3, m.value == -1, m.sequence(:s2, &c{ |s3,s2| s3 == s2 + 1 }) ] do |vars, engine|
      vars[:f3].value = vars[:f1].value + vars[:f2].value
      engine.modify vars[:f3]
      engine.retract vars[:f1]
      puts vars[:f3].sequence.to_s + ' == ' + vars[:f3].value.to_s
  end

# FACTS
fib1 = Fibonacci.new(150)

include Ruleby

engine :engine do |e|  
  rules.each do |r|
    e.assert_rule r
  end
  e.assert fib1
  e.match       
end