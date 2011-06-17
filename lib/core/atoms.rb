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

#tokens
module Ruleby
  module Core
  
  class Atom     
    attr_reader :tag, :proc, :slot, :template
    
    def initialize(tag, slot, template, block)
      @tag = tag
      @slot = slot
      @template = template
      @proc = block
    end    
    
    def to_s
      "#{self.class},#{@tag},#{@slot},#{@template}"
    end
  end
  
  # This kind of atom is used to match a simple condition.  
  # For example:
  # 
  #   a.person{ |p| p.is_a? Person }
  # 
  # So there are no references to other atoms.
  class PropertyAtom < Atom

    attr_reader :value

    def initialize(tag, slot, template, value, block)
      super(tag,slot,template, block)
      @value = value
    end

    def ==(atom)      
      shareable?(atom) && @tag == atom.tag
    end   
    
    def shareable?(atom)
      PropertyAtom === atom &&
             @slot == atom.slot &&
             @template == atom.template &&
             @proc == atom.proc &&
             @value == atom.value
    end
  end

  class FunctionAtom < Atom

    attr_reader :arguments

    def initialize(tag, template, arguments, block)
      @tag = tag
      @slot = nil
      @template = template
      @arguments = arguments
      @proc = block
    end

    def shareable?(atom)
      FunctionAtom === atom &&
             @template == atom.template &&
             @arguments == atom.arguments &&
             @proc == atom.proc
    end

    def to_s
      "#{self.class},#{@template},#{@arguments.inspect}"
    end
  end
  
  # This kind of atom is used to match just a single, hard coded value.  
  # For example:
  # 
  #   a.name == 'John' 
  # 
  # So there are no references to other atoms.
  class EqualsAtom < PropertyAtom
    EQUAL_PROC  = lambda {|x, y| x == y}

    def initialize(tag, slot, template, value)
      super(tag,slot,template, value, EQUAL_PROC)
    end

    def shareable?(atom)
      EqualsAtom === atom &&
             @slot == atom.slot &&
             @template == atom.template
    end
  end
  
  # This kind of atom is used to match a class type.  For example:
  # 
  #   'For each Person as :p'
  # 
  # It is only used at the start of a pattern.
  class HeadAtom < PropertyAtom
    HEAD_EQUAL_PROC  = lambda {|t, c| t == c}
    HEAD_INHERITS_PROC  = lambda {|t, c| t === c}

    def initialize(tag, template)
      if template.mode == :equals
        super tag, :class, template, template.clazz, HEAD_EQUAL_PROC
      elsif template.mode == :inherits
        super tag, :class, template, template.clazz, HEAD_INHERITS_PROC
      end
    end
    
    def shareable?(atom)
      HeadAtom === atom && @template == atom.template
    end
  end
  
  # This kind of atom is used for matching a value that is a variable.
  # For example:
  #
  #   #name == #:your_name
  #   
  # The expression for this atom depends on some other atom.  
  class ReferenceAtom < Atom  
    attr_reader :vars
    
    def initialize(tag, slot, vars, template, block)
      super(tag, slot, template, block)
      @vars = vars # list of referenced variable names
    end    
    
    def shareable?(atom)
      false
    end
    
    def ==(atom)      
      ReferenceAtom === atom &&
             @proc == atom.proc && 
             @tag == atom.tag && 
             @vars == atom.vars && 
             @template == atom.template
    end
    
    def to_s
      super + ", vars=#{vars.join(',')}"
    end
  end
  
  # This is an atom that references another atom that is in the same pattern.
  # Note that in a SelfReferenceAtom, the 'vars' argument must be a list of the
  # *slots* that this atom references (not the variable names)!
  class SelfReferenceAtom < ReferenceAtom
  end
  
  # This class encapsulates the criteria the HeadAtom uses to match.  The clazz
  # attribute represents a Class type, and the mode defines whether the head 
  # will match only class that are exactly a particular type, or if it will 
  # match classes that inherit that type also.
  class Template
    attr_reader :clazz
    attr_reader :mode
    
    def initialize(clazz,mode=:equals)
      @clazz = clazz
      @mode = mode
    end    
    
    def ==(df)
      Template === df && df.clazz == @clazz && df.mode == @mode
    end    
  end
  
  class AtomFactory
    # TODO add some convenience methods for creating atoms
  end

end
end
