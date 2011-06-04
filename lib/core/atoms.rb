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
    attr_reader :tag, :proc, :method_name, :template
    
    def initialize(tag, method_name, template, &block)
      @tag = tag
      @method_name = method_name
      @template = template
      @proc = Proc.new(&block) if block_given?
    end    
    
    def to_s
      "#{self.class},#{@tag},#{@method_name},#{@template}"
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
      shareable?(atom) && @tag == atom.tag
    end   
    
    def shareable?(atom)
      PropertyAtom === atom &&
             @method_name == atom.method_name &&
             @template == atom.template &&
             @proc == atom.proc 
    end
  end

  class FunctionAtom < Atom

    attr_reader :arguments

    def initialize(tag, template, arguments, block)
      @tag = tag
      @method_name = nil
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

  # TODO use this
  class BlockAtom < PropertyAtom
    def shareable?(atom)
      super && BlockAtom === atom && @proc == atom.proc
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
    def initialize(tag, method_name, template, value)
      super(tag,method_name,template)
      @value = value
    end
    
    def shareable?(atom)
      EqualsAtom === atom &&
             @method_name == atom.method_name &&
             @template == atom.template
    end
  end
  
  # This kind of atom is used to match a class type.  For example:
  # 
  #   'For each Person as :p'
  # 
  # It is only used at the start of a pattern.
  class HeadAtom < Atom
    def initialize(tag, template)
      if template.mode == :equals
        super tag, :class, template do |t| t == template.clazz end
      elsif template.mode == :inherits
        super tag, :class, template do |t| t === template.clazz end
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
    
    def initialize(tag, method_name, vars, template, &block)
      super(tag, method_name, template, &block)
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
  # *method_names* that this atom references (not the variable names)!
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