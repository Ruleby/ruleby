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

require 'ruleby'

include Ruleby

# NOTE this example uses the LeTigre DSL syntax.  In addition, its semantics are
# different from the other classes.
class FibonacciRulebook2 < Rulebook
  MAX_SEQUENCE = 100
  def rules
    rule :Calculate, {:priority => 2 },                               
      'Fibonacci as :f1 where #value != -1 #&& #sequence as :s1',
      'Fibonacci as :f2 where #value != -1 #&& #sequence == #:s1 + 1 as :s2',
      'Fibonacci as :f3 where #value == -1 #&& #sequence == #:s2 + 1' do |vars|
        retract vars[:f1]
        retract vars[:f3]
        if(vars[:f2].sequence == MAX_SEQUENCE)
          retract vars[:f2]
        else      
          f3 = Fibonacci.new(vars[:f2].sequence + 1, vars[:f1].value + vars[:f2].value)
          assert f3
          puts "#{f3.sequence} == #{f3.value}"
        end                 
    end    
  
    rule :Build, {:priority => 1},
      'Fibonacci as :f1 where #value != -1 #&& #sequence as :s1',
      'Fibonacci as :f2 where #value != -1 #&& #sequence == #:s1 + 1' do |vars| 
        f3 = Fibonacci.new(vars[:f2].sequence + 1, -1)
        assert f3
    end
  end
end

# NOTE
# In this class we demonstrate the Ferrari DSL syntax.  
class FibonacciRulebookFerrari < Rulebook
  def rules
   # Bootstrap1
    rule  :Bootstrap1,  {:priority => 4},
      [Fibonacci, :f, m.value == -1, m.sequence == 1 ] do |vars|  
        vars[:f].value = 1
        modify vars[:f]
        puts vars[:f].sequence.to_s + ' == ' + vars[:f].value.to_s      
    end  
 
    # Recurse
    rule :Recurse, {:priority => 3},
      [Fibonacci, :f, m.value == -1] do |vars|   
        f2 = Fibonacci.new(vars[:f].sequence - 1)
        assert f2
        puts 'recurse for ' + f2.sequence.to_s
    end  
  
    # Bootstrap2
    rule :Bootstrap2, 
      [Fibonacci, :f, m.value == -1 , m.sequence == 2] do |vars|    
        vars[:f].value = 1       
        modify vars[:f]
        puts vars[:f].sequence.to_s + ' == ' + vars[:f].value.to_s
    end
  
    # Calculate
    rule :Calculate,
      [Fibonacci,:f1, m.value.not== -1, {m.sequence => :s1}],
      [Fibonacci,:f2, m.value.not== -1, {m.sequence( :s1, &c{ |s2,s1| s2 == s1 + 1 } ) => :s2}],
      [Fibonacci,:f3, m.value == -1, m.sequence(:s2, &c{ |s3,s2| s3 == s2 + 1 }) ] do |vars|
        vars[:f3].value = vars[:f1].value + vars[:f2].value
        modify vars[:f3]
        retract vars[:f1]
        puts vars[:f3].sequence.to_s + ' == ' + vars[:f3].value.to_s
    end
  end
end