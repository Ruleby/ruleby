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
require 'fibonacci_rulebook'
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

include Ruleby

# FACTS
fib1 = Fibonacci.new(1,1)
fib2 = Fibonacci.new(2,1)

engine :engine do |e|  
  FibonacciRulebook2.new(e).rules
  e.assert fib1
  e.assert fib2
  e.match       
end