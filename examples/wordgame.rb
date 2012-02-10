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
    name :generate_combos
    rule [String, :a], [Fixnum, :x] do |v|
      assert Combination.new(v[:a], v[:x])
    end
    
    c1 = lambda {|t,d| ((d+d) % 10) == t }    
    c2 = lambda {|r,d,t,l| ((d+d+(10*l)+(10*l)) % 100) == ((10 * r) + t) }
    c3 = lambda {|e,d,l,a,r,t| ((d+d+(10*l)+(10*l)+(100*a)+(100*a)) % 1000) == ((100*e)+(10*r)+t) }
    c4 = lambda {|b,d,l,a,r,n,e,t| ((d+d+(10*l)+(10*l)+(100*a)+(100*a)+(1000*r)+(1000*n)) % 10000) == ((1000*b)+(100*e)+(10*r)+t) }
    c5 = lambda {|g,d,l,a,r,n,e,o,b,t| (d+d+(10*l)+(10*l)+(100*a)+(100*a)+(1000*r)+(1000*n)+(10000*e)+(10000*o)+(100000*g)+(100000*d)) == ((100000*r)+(10000*o)+(1000*b)+(100*e)+(10*r)+t) }
 
    name :find_solution
    rule [Combination, where{self.a=='D'; self.x >> :d}],
        [Combination, where{self.a=='T'; ((self.x.not==??)<<:d)>>:t; self.x(&c1)<<:d}],      
        [Combination, where{self.a=='L'; ((self.x.not==??)<<:d)>>:l; (self.x.not==??)<<:t}],
        [Combination, where{
          self.a=='R'
          ((self.x.not==??)<<:d)>>:r
          (self.x.not==??)<<:t
          (self.x.not==??)<<:l
          self.x(&c2).<< :d,:t,:l
          }],
        [Combination,where{
          self.a=='A'
          ((self.x.not==??)<<:d)>>:a
          (self.x.not==??)<<:t
          (self.x.not==??)<<:l
          (self.x.not==??)<<:r
          }],
        [Combination, where{ |m|
          m.a=='E'
          ((m.x.not==??)<<:d)>>:e 
          (m.x.not==??)<<:t
          (m.x.not==??)<<:l
          (m.x.not==??)<<:r
          (m.x.not==??)<<:a
          m.x(&c3).<< :d,:l,:a,:r,:t
          }],
        [Combination, where{ |m|
          m.a=='N'
          ((m.x.not==??)<<:d)>>:n 
          (m.x.not==??)<<:t 
          (m.x.not==??)<<:l 
          (m.x.not==??)<<:r 
          (m.x.not==??)<<:a
          (m.x.not==??)<<:e
          }],
        [Combination, where {|m|
          m.a=='B'
          ((m.x.not==??)<<:d)>>:b 
          (m.x.not==??)<<:t 
          (m.x.not==??)<<:l 
          (m.x.not==??)<<:r 
          (m.x.not==??)<<:a 
          (m.x.not==??)<<:e 
          (m.x.not==??)<<:n
          m.x(&c4).<< :d,:l,:a,:r,:n,:e,:t
          }],    
        [Combination, where {|m|
          m.a=='O'
          ((m.x.not==??)<<:d)>>:o
          (m.x.not==??)<<:t
          (m.x.not==??)<<:l
          (m.x.not==??)<<:r 
          (m.x.not==??)<<:a 
          (m.x.not==??)<<:e 
          (m.x.not==??)<<:n 
          (m.x.not==??)<<:b
          }],    
        [Combination, where {|m|
          m.a=='G'
          ((m.x.not==??)<<:d)>>:g 
          (m.x.not==??)<<:t 
          (m.x.not==??)<<:l 
          (m.x.not==??)<<:r 
          (m.x.not==??)<<:a 
          (m.x.not==??)<<:e 
          (m.x.not==??)<<:n 
          (m.x.not==??)<<:b 
          (m.x.not==??)<<:o 
          m.x(&c5).<< :d,:l,:a,:r,:n,:e,:o,:b,:t
          }] do |v|
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