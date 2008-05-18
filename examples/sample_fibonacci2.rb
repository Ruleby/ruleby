# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner, Matt Smith
#

$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib/')
require 'ruleby'
include Ruleby
MAX_SEQUENCE = 100
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


# FACTS
fib1 = Fibonacci.new(1,1)
fib2 = Fibonacci.new(2,1)

engine :engine do |e|
  File.open('sample_fibonacci2.yml') do |f|
    YamlDsl.load_rules(f, e)
  end
  e.assert fib1
  e.assert fib2
  e.match
end
