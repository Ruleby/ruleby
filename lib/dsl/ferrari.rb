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
  module Ferrari
    class RulebookHelper    
      def initialize(engine)
        @engine = engine
      end
    
      attr_reader :engine
    
      def rule(name, *args, &block) 
        options = args[0].kind_of?(Hash) ? args.shift : {}        
        
        r = RuleBuilder.new name
        args.each do |arg|
          if arg.kind_of? Array
            r.when(*arg)
          else
            raise 'Invalid condition.  All or none must be Arrays.'
          end
        end
        
        r.then(&block)
        r.priority = options[:priority] if options[:priority]
        
        @engine.assert_rule(r.build_rule)
      end
      
    end
    
    class RuleBuilder
    
      def initialize(name, pattern=nil, action=nil, priority=0) 
        @name = name
        @pattern = pattern
        @action = action  
        @priority = priority            
        
        @tags = {}
        @methods = {}
        @when_counter = 0
      end   
        
      def when(*args)      
        clazz = AtomBuilder === args[0] ? nil : args.shift
        is_not = false
        mode = :equals
        while clazz.is_a? Symbol          
          if clazz == :not || clazz == :~
            is_not = true
          elsif clazz == :is_a? || clazz == :kind_of? || clazz == :instance_of?
            mode = :inherits
          elsif clazz == :exists?
            raise 'The \'exists\' quantifier is not yet supported.'
          end
          clazz = args.empty? ? nil : args.shift 
        end
        
        if clazz == nil
          clazz = Object
          mode = :inherits
        end
        
        deftemplate = Core::DefTemplate.new clazz, mode        
        atoms = []
        @when_counter += 1
        htag = Symbol === args[0] ? args.shift : GeneratedTag.new
        head = Core::HeadAtom.new htag, deftemplate
        @tags[htag] = @when_counter
        
        args.each do |arg|
          if arg.kind_of? Hash
            arg.each do |ab,tag|
              ab.tag = tag
              ab.deftemplate = deftemplate
              @tags[tag] = @when_counter
              @methods[tag] = ab.name
              atoms.push *ab.build_atoms(@tags, @methods, @when_counter)
            end
          elsif arg.kind_of? AtomBuilder
            arg.tag = GeneratedTag.new
            arg.deftemplate = deftemplate
            @methods[arg.tag] = arg.name
            atoms.push *arg.build_atoms(@tags, @methods, @when_counter)
          elsif arg == false
            raise 'The != operator is not allowed.'
          else
            raise "Invalid condition: #{arg}"
          end
        end  
        
        if is_not 
          p = mode==:inherits ? Core::NotInheritsPattern.new(head, atoms) : 
                                Core::NotPattern.new(head, atoms)
        else
          p = mode==:inherits ? Core::InheritsPattern.new(head, atoms) : 
                                Core::ObjectPattern.new(head, atoms)
        end
        @pattern = @pattern ? Core::AndPattern.new(@pattern, p) : p
        
        return nil
      end
      
      def then(&block)
        @action = Core::Action.new(&block)  
        @action.name = @name
        @action.priority = @priority
      end
          
      def priority
        return @priority
      end
      
      def priority=(p)
        @priority = p
        @action.priority = @priority
      end 
        
      def build_rule
        Core::Rule.new @name, @pattern, @action, @priority
      end
    end
    
    class MethodBuilder  
      public_instance_methods.each do |m|
        a = [:method_missing, :new, :public_instance_methods, :__send__, :__id__]
        undef_method m.to_sym unless a.include? m.to_sym
      end
    
      def method_missing(method_id, *args, &block)
        ab = AtomBuilder.new method_id
        if block_given?
          args.each do |arg|   
            ab.bindings.push BindingBuilder.new(arg, method_id)
          end
          ab.block = block
        elsif args.size > 0
          puts args.class.to_s + ' --- ' + args.to_s
          raise 'Arguments not supported for short-hand conditions' 
        end
        return ab
      end
    end
    
    class BindingBuilder  
      attr_accessor :tag, :method
      def initialize(tag,method=nil)
        @tag = tag
        @method = method
      end
      
      def +(arg)
        raise 'Cannot use operators in short-hand mode!'
      end
      
      def -(arg)
        raise 'Cannot use operators in short-hand mode!'
      end
      
      def /(arg)
        raise 'Cannot use operators in short-hand mode!'
      end
      
      def *(arg)
        raise 'Cannot use operators in short-hand mode!'
      end
      
      def to_s
        "BindingBuilder @tag=#{@tag}, @method=#{@method}"
      end
    end
    
    class AtomBuilder
      attr_accessor :tag, :name, :bindings, :deftemplate, :block
      
      def initialize(method_id)
        @name = method_id
        @deftemplate = nil
        @tag = GeneratedTag.new
        @bindings = []
        @block = lambda {|x| true}
        @child_atom_builders = []
      end
      
      def method_missing(method_id, *args, &block)
        if method_id == :not
          return NotOperatorBuilder.new(@name)
        end
      end
      
      def ==(value)
        @atom_type = :equals
        @value = value
        create_block value, lambda {|x,y| x == y}, lambda {|x| x == value}; self
      end
      
      def >(value)
        create_block value, lambda {|x,y| x > y}, lambda {|x| x > value}; self
      end
      
      def <(value)
        create_block value, lambda {|x,y| x < y}, lambda {|x| x < value}; self
      end
      
      def =~(value)
        create_block value, lambda {|x,y| x =~ y}, lambda {|x| x =~ value}; self
      end
      
      def <=(value)
        create_block value, lambda {|x,y| x <= y}, lambda {|x| x <= value}; self
      end
      
      def >=(value)
        create_block value, lambda {|x,y| x >= y}, lambda {|x| x >= value}; self
      end 
      
      def =~(value)
        create_block value, lambda {|x,y| x =~ y}, lambda {|x| x =~ value}; self
      end 
      
      def build_atoms(tags,methods,when_id)
        atoms = @child_atom_builders.map { |atom_builder|
          tags[atom_builder.tag] = when_id
          methods[atom_builder.tag] = atom_builder.name
          atom_builder.build_atoms(tags,methods,when_id)
        }.flatten || []

        if @bindings.empty?
          if @atom_type == :equals 
            return atoms << Core::EqualsAtom.new(@tag, @name, @deftemplate, @value)
          else
            return atoms << Core::PropertyAtom.new(@tag, @name, @deftemplate, &@block)
          end
        end
        
        if references_self?(tags,when_id)
          bind_methods = @bindings.collect{ |bb| methods[bb.tag] }
          atoms << Core::SelfReferenceAtom.new(@tag,@name,bind_methods,@deftemplate,&@block)
        else
          bind_tags = @bindings.collect{ |bb| bb.tag }
          atoms << Core::ReferenceAtom.new(@tag,@name,bind_tags,@deftemplate,&@block)
        end
      end
      
      private
      def references_self?(tags,when_id)
        ref_self = 0
        @bindings.each do |bb|
          if (tags[bb.tag] == when_id)
            ref_self += 1
          end
        end
        
        if ref_self > 0 and ref_self != @bindings.size
          raise 'Binding to self and another pattern in the same condition is not yet supported.'
        end
        
        return ref_self > 0
      end
      
      def create_block(value, ref_block, basic_block)
        if value && value.kind_of?(BindingBuilder)
          @bindings = [value]
          @block = ref_block
        elsif value && value.kind_of?(AtomBuilder)
          @child_atom_builders << value
          @bindings = [BindingBuilder.new(value.tag)]
          @block = ref_block
        else
          @block = basic_block
        end
      end
    end
    
    class NotOperatorBuilder < AtomBuilder
      def ==(value)
        create_block value, lambda {|x,y| x != y}, lambda {|x| x != value}; self
      end
    end
  end
end
