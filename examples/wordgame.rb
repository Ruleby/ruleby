# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner
#


# This example solves the number puzzle problem where
#    GERALD 
#  + DONALD
#    ------
#  = ROBERT

$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib/')
require 'ruleby'

include Ruleby

class Combination
  attr:a
  attr:x
  def initialize(a,x)
    @a = a
    @x = x
  end
end

class WordGameRulebook < Ruleby::Rulebook
  def rules
    rule :generate_combos, [String, :a], [Fixnum, :x] do |v|
      assert Combination.new(v[:a], v[:x])
    end
    
    c1 = c{|t,d| ((d+d) % 10) == t }    
    c2 = c{|r,d,t,l| ((d+d+(10*l)+(10*l)) % 100) == ((10 * r) + t) }
    c3 = c{|e,d,l,a,r,t| ((d+d+(10*l)+(10*l)+(100*a)+(100*a)) % 1000) == ((100*e)+(10*r)+t) }
    c4 = c{|b,d,l,a,r,n,e,t| ((d+d+(10*l)+(10*l)+(100*a)+(100*a)+(1000*r)+(1000*n)) % 10000) == ((1000*b)+(100*e)+(10*r)+t) }
    c5 = c{|g,d,l,a,r,n,e,o,b,t| (d+d+(10*l)+(10*l)+(100*a)+(100*a)+(1000*r)+(1000*n)+(10000*e)+(10000*o)+(100000*g)+(100000*d)) == ((100000*r)+(10000*o)+(1000*b)+(100*e)+(10*r)+t) }
 
    rule :find_solution, 
        [Combination, m.a=='D', {m.x => :d}],
        [Combination, m.a=='T', {m.x.not==b(:d)=>:t}, m.x(:d, &c1)],      
        [Combination, m.a=='L', {m.x.not==b(:d)=>:l}, m.x.not==b(:t)],
        [Combination, m.a=='R', {m.x.not==b(:d)=>:r}, m.x.not==b(:t), m.x.not==b(:l), 
          m.x(:d,:t,:l, &c2)],
        [Combination, m.a=='A', {m.x.not==b(:d)=>:a}, m.x.not==b(:t), m.x.not==b(:l), m.x.not==b(:r)],
        [Combination, m.a=='E', {m.x.not==b(:d)=>:e}, m.x.not==b(:t), m.x.not==b(:l), m.x.not==b(:r), 
          m.x.not==b(:a), m.x(:d,:l,:a,:r,:t, &c3)],
        [Combination, m.a=='N', {m.x.not==b(:d)=>:n}, m.x.not==b(:t), m.x.not==b(:l), m.x.not==b(:r), 
          m.x.not==b(:a), m.x.not==b(:e)],
        [Combination, m.a=='B', {m.x.not==b(:d)=>:b}, m.x.not==b(:t), m.x.not==b(:l), m.x.not==b(:r), 
          m.x.not==b(:a), m.x.not==b(:e), m.x.not==b(:n), m.x(:d,:l,:a,:r,:n,:e,:t, &c4)],    
        [Combination, m.a=='O', {m.x.not==b(:d)=>:o}, m.x.not==b(:t), m.x.not==b(:l), m.x.not==b(:r), 
          m.x.not==b(:a), m.x.not==b(:e), m.x.not==b(:n), m.x.not==b(:b)],    
        [Combination, m.a=='G', {m.x.not==b(:d)=>:g}, m.x.not==b(:t), m.x.not==b(:l), m.x.not==b(:r), 
          m.x.not==b(:a), m.x.not==b(:e), m.x.not==b(:n), m.x.not==b(:b), m.x.not==b(:o), 
          m.x(:d,:l,:a,:r,:n,:e,:o,:b,:t, &c5)] do |v|
      puts "One Solution is:"
      puts "  G = #{v[:g]}"
      puts "  E = #{v[:e]}"
      puts "  R = #{v[:r]}" 
      puts "  A = #{v[:a]}" 
      puts "  L = #{v[:l]}"
      puts "  D = #{v[:d]}"
      puts "  O = #{v[:o]}"
      puts "  N = #{v[:n]}"
      puts "  B = #{v[:b]}"
      puts "  T = #{v[:t]}"
      puts ""
      puts "   #{v[:g]} #{v[:e]} #{v[:r]} #{v[:a]} #{v[:l]} #{v[:d]}"
      puts " + #{v[:d]} #{v[:o]} #{v[:n]} #{v[:a]} #{v[:l]} #{v[:d]}"
      puts "   ------"
      puts " = #{v[:r]} #{v[:o]} #{v[:b]} #{v[:e]} #{v[:r]} #{v[:t]}"
    end
  end
end

e = engine :e do |e|
  WordGameRulebook.new(e).rules
  e.assert 0
  e.assert 1
  e.assert 2
  e.assert 3
  e.assert 4
  e.assert 5
  e.assert 6
  e.assert 7
  e.assert 8
  e.assert 9
  e.assert 'G'
  e.assert 'E'
  e.assert 'R'
  e.assert 'A'
  e.assert 'L'
  e.assert 'D'
  e.assert 'O'
  e.assert 'N'
  e.assert 'B'
  e.assert 'T'
end

e.match