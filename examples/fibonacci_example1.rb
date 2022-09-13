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
require_relative 'fibonacci_rulebook'
class Fibonacci
  def initialize(sequence,value=-1)
    @sequence = sequence
    @value = value 
  end
  
  attr_reader :sequence  
  attr :value, true
  
  def to_s
    return '['+super + " sequence=" + @sequence.to_s + ",value=" + @value.to_s + ']'
  end
end

include Ruleby

# This example is borrowed from the JBoss-Rule project.

# FACTS
fib1 = Fibonacci.new(150)

t1 = Time.new
engine :engine do |e|
  FibonacciRulebookFerrari.new(e).rules
  e.assert fib1
  e.match   
end
t2 = Time.new
diff = t2.to_f - t1.to_f
puts diff.to_s
