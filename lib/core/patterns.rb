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

module Ruleby
  module Core

  class Pattern
  end
  
  # This class represents a pattern that is looking for the existence of some
  # object. It contains a list of 'atoms' that represent the properties of
  # the class that we are looking for.
  class ObjectPattern < Pattern
    attr_reader :atoms
    
    def initialize(head, atoms)
      @atoms = [head] + atoms     
    end
    
    def head
      @atoms[0]
    end      
    
    def ==(pattern)
      if pattern.class == self.class
        atoms = pattern.atoms
        if(@atoms.size == atoms.size)
          (0..@atoms.size).each do |i|
            if !(@atoms[i] == atoms[i])
              return false
            end
          end
          return true
        end
      end
      return false
    end
   
    def to_s
      return '(' + @atoms.join('|') + ')'
    end
  end
  
  class InheritsPattern < ObjectPattern
  end

  class CollectPattern < ObjectPattern    
  end
  
  # This class represents a pattern that is looking for the absence of some
  # object (rather than the existence of).  In all respects, it is the same as
  # an ObjectPattern, but it is handled differently by the inference engine.
  class NotPattern < ObjectPattern
  end
  
  class NotInheritsPattern < InheritsPattern
  end
  
  # A composite pattern represents a logical conjunction of two patterns.  The
  # inference engine interprets this differently from an ObjectPattern because
  # it simply aggregates patterns.  
  class CompositePattern < Pattern
        
    attr_reader :left_pattern
    attr_reader :right_pattern
    
    def initialize(left_pattern, right_pattern)
      @left_pattern = left_pattern
      @right_pattern = right_pattern
    end    
    
    def atoms
      atoms = []
      atoms.push @left_pattern.atoms
      atoms.push @right_pattern.atoms
      return atoms
    end
  end
  
  class AndPattern < CompositePattern
  
    def initialize(left_pattern, right_pattern)
      super(left_pattern, right_pattern)
      @head = :and    
    end
     
  end
  
  class OrPattern < CompositePattern
    
    def initialize(left_pattern, right_pattern)
      super(left_pattern, right_pattern)
      @head = :or
    end

  end
  
  class InitialFactPattern < ObjectPattern
    def initialize
      deftemplate = Template.new InitialFact, :equals
      htag = GeneratedTag.new
      head = HeadAtom.new htag, deftemplate
      super(head, [])
    end
  end

  class PatternFactory
    # TODO add some convenience methods for creating patterns
  end
end
end