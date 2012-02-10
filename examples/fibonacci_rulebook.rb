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

