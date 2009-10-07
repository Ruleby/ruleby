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
    attr_reader :tag, :proc, :method, :deftemplate
    
    def initialize(tag, method, deftemplate, &block)
      @tag = tag
      @method = method
      @deftemplate = deftemplate
      @proc = Proc.new(&block) if block_given?
    end    
    
    def to_s
      return "#{self.class},#{@tag},#{@method},#{@deftemplate}"
    end
  end
  
  # This kind of atom is used to match a simple condition.  
  # For example:
  # 
  #   a.person{ |p| p.is_a? Person }
  # 
  # So there are no references to other atoms.
  class PropertyAtom < Atom    
    def ==(atom)      
      return shareable?(atom) && @tag == atom.tag
    end   
    
    def shareable?(atom)
      return PropertyAtom === atom && 
             @method == atom.method && 
             @deftemplate == atom.deftemplate && 
             @proc == atom.proc 
    end
  end  
  
  # TODO use this
  class BlockAtom < PropertyAtom
    def shareable?(atom)
      return super &&
             BlockAtom === atom &&              
             @proc == atom.proc 
    end
  end
  
  # This kind of atom is used to match just a single, hard coded value.  
  # For example:
  # 
  #   a.name == 'John' 
  # 
  # So there are no references to other atoms.
  class EqualsAtom < PropertyAtom
    attr_reader :value
    def initialize(tag, method, deftemplate, value)
      super(tag,method,deftemplate)
      @value = value
    end
    
    def shareable?(atom)
      return EqualsAtom === atom && 
             @method == atom.method && 
             @deftemplate == atom.deftemplate 
    end
  end
  
  # This kind of atom is used to match a class type.  For example:
  # 
  #   'For each Person as :p'
  # 
  # It is only used at the start of a pattern.
  class HeadAtom < Atom
    def initialize(tag, deftemplate)   
      if deftemplate.mode == :equals
        super tag, :class, deftemplate do |t| t == deftemplate.clazz end
      elsif deftemplate.mode == :inherits
        super tag, :class, deftemplate do |t| t === deftemplate.clazz end
      end
    end
    
    def shareable?(atom)
      return HeadAtom === atom && @deftemplate == atom.deftemplate
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
    
    def initialize(tag, method, vars, deftemplate, &block) 
      super(tag, method, deftemplate, &block)
      @vars = vars # list of referenced variable names
    end    
    
    def shareable?(atom)
      false
    end
    
    def ==(atom)      
      return ReferenceAtom === atom && 
             @proc == atom.proc && 
             @tag == atom.tag && 
             @vars == atom.vars && 
             @deftemplate == atom.deftemplate
    end
    
    def to_s
      return super + ", vars=#{vars.join(',')}"
    end
  end
  
  # This is an atom that references another atom that is in the same pattern.
  # Note that in a SelfReferenceAtom, the 'vars' argument must be a list of the
  # *methods* that this atom references (not the variable names)!
  class SelfReferenceAtom < ReferenceAtom
  end
  
  # This class encapsulates the criteria the HeadAtom uses to match.  The clazz
  # attribute represents a Class type, and the mode defines whether the head 
  # will match only class that are exactly a particular type, or if it will 
  # match classes that inherit that type also.
  class DefTemplate
    attr_reader :clazz
    attr_reader :mode
    
    def initialize(clazz,mode=:equals)
      @clazz = clazz
      @mode = mode
    end    
    
    def ==(df)
      DefTemplate === df && df.clazz == @clazz && df.mode == @mode
    end    
  end
  
  class AtomFactory
    # TODO add some convenience methods for creating atoms
  end

end
end