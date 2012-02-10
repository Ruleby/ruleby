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

class FibonacciRulebook1 < Rulebook
  def rules
   # Bootstrap1
    name :Bootstrap1
    opts :priority => 4
    rule [Fibonacci, :f, where {self.value == -1; self.sequence == 1 }] do |vars|
      vars[:f].value = 1
      modify vars[:f]
      puts vars[:f].sequence.to_s + ' == ' + vars[:f].value.to_s      
    end  
 
    # Recurse
    name :Recurse
    opts :priority => 3
    rule [Fibonacci, :f, where { self.value == -1 }] do |vars|
      f2 = Fibonacci.new(vars[:f].sequence - 1)
      assert f2
      puts 'recurse for ' + f2.sequence.to_s
    end  
  
    # Bootstrap2
    rule [Fibonacci, :f, where { self.value == -1; self.sequence == 2 }] do |vars|
      vars[:f].value = 1       
      modify vars[:f]
      puts vars[:f].sequence.to_s + ' == ' + vars[:f].value.to_s
    end
  
    # Calculate
    rule [Fibonacci,:f1, where {self.value.not== -1; self.sequence.>> :s1}],
      [Fibonacci,:f2, where {self.value.not== -1; (self.sequence(&lambda{|s2,s1| s2 == s1 + 1 }).<<:s1).>>:s2}],
      [Fibonacci,:f3, where {self.value == -1; self.sequence(&lambda{|s3,s2| s3 == s2 + 1 }).<<:s2}] do |vars|
        vars[:f3].value = vars[:f1].value + vars[:f2].value
        modify vars[:f3]
        retract vars[:f1]
        puts vars[:f3].sequence.to_s + ' == ' + vars[:f3].value.to_s
    end
  end
end

# This example is borrowed from the JBoss-Rule project.

# FACTS
fib1 = Fibonacci.new(150)

t1 = Time.new
engine :engine do |e|
  FibonacciRulebook1.new(e).rules
  e.assert fib1
  e.match   
end
t2 = Time.new
diff = t2.to_f - t1.to_f
puts diff.to_s