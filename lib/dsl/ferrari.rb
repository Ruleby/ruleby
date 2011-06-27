# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2010 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner, Matt Smith
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

        rules = Ruleby::Ferrari.parse_containers(args, RulesContainer.new).build(name,options,@engine,&block)
        rules.each do |r|
          engine.assert_rule(r)
        end
      end
    end
    
    def self.parse_containers(args, container=Container(:and), parent=nil)
      con = nil
      if(container.kind_of?(RulesContainer))
        con = Container.new(:and)
      else
        con = container
      end
      args.each do |arg|
        if arg.kind_of? Array
          con << PatternContainer.new(arg)
        elsif arg.kind_of? AndBuilder
          con << parse_containers(arg.conditions, Container.new(:and), container)
        elsif arg.kind_of? OrBuilder  
          con << parse_containers(arg.conditions, Container.new(:or), container)
        else
          raise 'Invalid condition. Must be an OR, AND or an Array.'
        end
      end
      if container.kind_of?(RulesContainer)
        container << con
      end
      return container
    end
    
    class RulesContainer < Array
      def handle_branching
        ands = []
        each do |x|
          f = x.flatten_patterns
          if f.or?
            f.each do |o|
              ands << o
            end
          else
            ands << f
          end
        end
        ands
      end
      
      def build(name, options, engine, &block)
        handle_branching.map do |container|
          build_rule(name, container, options, &block)
        end
      end
      
      def build_rule(name, container, options, &block)
        r = RuleBuilder.new name
        container.build r
        r.then(&block)
        r.priority = options[:priority] if options[:priority]
        r.build_rule
      end
    end


    class Container < Array
      attr_accessor :kind
      
      def initialize(kind, *vals)
        @kind = kind
        self.push(*vals)
      end

      def flatten_patterns
        if or?
          patterns = []
          each do |c|
            f = c.flatten_patterns
            if f.and?
              patterns << f
            else
              f.each do |o|
                # i hope this is safe... not entirely sure
                patterns << (o.size == 1 ? o.first : o)
#                patterns << o
              end
            end
          end

          Container.new(:or, *patterns)
        elsif and?
          patterns = []
          or_patterns = []
          each do |c|
            child_patterns = c.flatten_patterns
            if child_patterns.or? and child_patterns.size > 1
              or_patterns << child_patterns
            else
              patterns.push(*child_patterns)
            end
          end
          if or_patterns.empty?
            flat = Container.new(:and)
            flat.push(*patterns)
          else
            flat = Container.new(:or)

            x = or_patterns[1..-1]
            if x.empty?
              or_pattern_products = or_patterns[0].product()
            else
              or_pattern_products = or_patterns[0].product(*x)
            end

            or_pattern_products.each do |op|
              c = Container.new(:and)
              c.push(*patterns)
              c.push(*op)
              flat << c
            end
          end
          return flat
        end
      end
      
      def build(builder)
        if self.or?
          # OrContainers are never built, they just contain containers that
          # will be transformed into AndContainers.
          raise 'Invalid Syntax'
        end
        self.each do |x|
          x.build builder
        end
      end
      
      def or?
        return kind == :or
      end
      
      def and?
        return kind == :and
      end
    end
    
    class PatternContainer
      def initialize(condition)
        @condition = condition
      end

      def size
        1
      end

      def first
        self
      end

      def flatten_patterns
        Container.new(:and, self)
      end

      def build(builder)
        builder.when(*@condition)
      end
      
      def process_tree
        # there is no tree to process
        false
      end
      
      def or?
        false
      end
      
      def and?
        false
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
        is_collect = false
        mode = :equals
        while clazz.is_a? Symbol          
          if clazz == :not || clazz == :~
            is_not = true
          elsif clazz == :is_a? || clazz == :kind_of? || clazz == :instance_of?
            mode = :inherits
          elsif clazz == :collect
            is_collect = true
          elsif clazz == :exists?
            raise 'The \'exists\' quantifier is not yet supported.'
          end
          clazz = args.empty? ? nil : args.shift 
        end

        if clazz == nil
          clazz = Object
          mode = :inherits
        end

        deftemplate = Core::Template.new clazz, mode
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
          elsif arg.kind_of? FunctionBuilder
            atoms.push arg.build_atom(GeneratedTag.new, deftemplate)
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
                                is_collect ? Core::CollectPattern.new(head, atoms) :
                                             Core::ObjectPattern.new(head, atoms)
        end
        @pattern = @pattern ? Core::AndPattern.new(@pattern, p) : p
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
        # maybe we shouldn't be undefing object_id.  What are the implications?  Can we make object_id a
        # pass through to the underlying object's object_id?
        a = [:method_missing, :new, :public_instance_methods, :__send__, :__id__, :object_id]
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
        ab
      end
    end

    class FunctionBuilder
      def initialize(args, block)
        @args = args
        @function = block
      end

      def build_atom(tag, template)
        Core::FunctionAtom.new(tag, template, @args, @function)
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

      EQ_PROC = lambda {|x,y| x and x == y}
      GT_PROC = lambda {|x,y| x and x > y}
      LT_PROC = lambda {|x,y| x and x < y}
      MATCH_PROC = lambda {|x,y| x and x =~ y}
      LTE_PROC = lambda {|x,y| x and x <= y}
      GTE_PROC = lambda {|x,y| x and x >= y}
      TRUE_PROC = lambda {|x| true}

      def initialize(method_id)
        @name = method_id
        @deftemplate = nil
        @tag = GeneratedTag.new
        @bindings = []
        @block = TRUE_PROC
        @child_atom_builders = []
      end
      
      def method_missing(method_id, *args, &block)
        if method_id == :not
          NotOperatorBuilder.new(@name)
        end
      end
      
      def ==(value)
        @atom_type = :equals
        create_block value, EQ_PROC
        self
      end
      
      def >(value)
        create_block value, GT_PROC
        self
      end
      
      def <(value)
        create_block value, LT_PROC
        self
      end
      
      def =~(value)
        create_block value, MATCH_PROC
        self
      end
      
      def <=(value)
        create_block value, LTE_PROC
        self
      end
      
      def >=(value)
        create_block value, GTE_PROC
        self
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
            return atoms << Core::PropertyAtom.new(@tag, @name, @deftemplate, @value, @block)
          end
        end
        
        if references_self?(tags,when_id)
          bind_methods = @bindings.collect{ |bb| methods[bb.tag] }
          atoms << Core::SelfReferenceAtom.new(@tag,@name,bind_methods,@deftemplate,@block)
        else
          bind_tags = @bindings.collect{ |bb| bb.tag }
          atoms << Core::ReferenceAtom.new(@tag,@name,bind_tags,@deftemplate,@block)
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
        
        ref_self > 0
      end
      
      def create_block(value, block)
        @block = block
        if value && value.kind_of?(BindingBuilder)
          @bindings = [value]
        elsif value && value.kind_of?(AtomBuilder)
          @child_atom_builders << value
          @bindings = [BindingBuilder.new(value.tag)]
        else
          @value = value
        end
      end
    end
    
    class NotOperatorBuilder < AtomBuilder
      NOT_PROC = lambda {|x,y| x != y}
      def ==(value)
        create_block value, NOT_PROC
        self
      end
    end

    class OrBuilder 
      attr_reader :conditions
      def initialize(conditions)
        @conditions = conditions
      end
    end

    class AndBuilder
      attr_reader :conditions
      def initialize(conditions)
        @conditions = conditions
      end
    end
  end
end
