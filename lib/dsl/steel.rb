# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Matt Smith
#

module Ruleby
  module Steel
    class RulebookHelper

      include Ruleby
      def initialize(engine)
        raise 'This DSL is deprecated'
        @engine = engine
      end
    
      attr_reader :engine
    
      def rule(name, &block)
        r = Steel::RuleBuilder.new name
        yield r if block_given?
        @engine.assert_rule r.build_rule
        r
      end
     
    end
    
    class RuleBuilder
    
      def initialize(name, pattern=nil, action=nil, priority=0) 
        @name = name
        @pattern = pattern
        @action = action  
        @priority = priority    
      end   
        
      def when(&block)
        wb = WhenBuilder.new
        yield wb
        @pattern = wb.pattern
      end
      
      def then(&block)
        @action = Core::Action.new(&block)  
        @action.name = @name
        @action.priority = @priority
      end
      
      def when=(pattern)
        @pattern = pattern
      end
      
      def then=(action)
        @action = action
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
        r = Ruleby::Core::Rule.new @name, @pattern, @action, @priority
      end
    end
    
    class WhenBuilder #< RulebookHelper
      def initialize()
        @pattern_hash = Hash.new
        @pattern_keys = []
      end
      
      def method_missing(method_id, *args, &block)
        method = method_id.to_sym
        wi = nil
        if @pattern_hash.key? method
          wi = @pattern_hash[method]
        elsif :not == method
          @pattern_keys.push method
          return self
        else
          wi = WhenInternal.new method, args[0]
          @pattern_hash[method] = wi
          @pattern_keys.push method
        end
        return wi
      end
      
      def pattern
        operands = []
        nt = false
        @pattern_keys.each do |key|
          if :not != key
            wi = @pattern_hash[key]
            tag = wi.tag
            type = wi.type
            atoms = wi.to_atoms
            p = nil
            if nt
              p = Ruleby::Core::NotPattern.new(tag, type, atoms)
              nt = false
            else
              p = Ruleby::Core::ObjectPattern.new(tag, type, atoms)
            end
            operands = operands + [p]
          else
            nt = true
          end
        end
        return and_pattern(operands)
      end
      
      def and_pattern(operands)
        # TODO raise exception if referenceAtoms from the right do not
        # have the values they referenece in the left
        # TODO raise exception if there are repeated tags?
        left = nil
        operands.each do |operand|
          if left.nil?
            left = operand
          else           
            right = operand
            left = Ruleby::Core::AndPattern.new(left, right)
          end
        end
        left
      end 
      
      def or_pattern(operands)
        # TODO raise exception if referenceAtoms from the right do not
        # have the values they referenece in the left
        # TODO raise exception if there are repeated tags?
        left = nil
        operands.each do |operand|
          if left.nil?
            left = operand
          else           
            right = operand
            left = Ruleby::Core::OrPattern.new(left, right)
          end
        end
        left
      end
    end
    
    class WhenInternal
      public_instance_methods.each do |m|
        a = [:method_missing, :new, :public_instance_methods, :__send__, :__id__]
        undef_method m.to_sym unless a.include? m.to_sym
      end
      
      attr_reader :tag, :type
      def initialize(tag, type)
        @tag = tag
        @type = type
        @builder = WhenPropertyBuilder.new self
      end
      
      def to_atoms
        atoms = []
        tags = {@tag => :class}
        @builder.property_hash.each_value do |wp|
          tags[wp.tag] = wp.name if wp.tag
        end
        @builder.property_keys.each do |key|
          wp = @builder.property_hash[key]
          atoms = atoms + [wp.to_atom(tags)]
        end
        return atoms
      end
      
      def &
        return self
      end
      
      def method_missing(method_id, *args, &block)
        m = method_id.to_s
        suffix = m.to_s[-1..-1]
        if suffix == '='
          new_m = m[0,m.size-1]
          if args[0].class == Array && args[0].size > 1 && args[0][1] == :% 
            wp = @builder.create new_m do |x,y| x == y end
            wp.references args[0][0]
            return wp
          else
            wp = @builder.create new_m do |x| x == args[0] end
            return wp
          end
        else
          wp = @builder.create(m, &block)
          if args.size > 0 && args[0]
            if block_given?
              wp.references args[0]
            else
              wp.tag = args[0]
            end
          end
          return wp       
        end     
      end
    end
      
    class WhenPropertyBuilder
      attr_reader:property_hash
      attr_reader:property_keys
      
      def initialize(parent)
        @parent = parent
        @property_hash = Hash.new
        @property_keys = []
      end
      
      def create(method_id,&block)
        method = method_id.to_sym
        wp = nil
        if @property_hash.key? method
          wp = @property_hash[method]
        else
          wp = WhenProperty.new @parent, method do |p| true end
          @property_hash[method] = wp
          @property_keys.push method
        end
        if block_given?
          wp.block = block
        end
        return wp
      end
    end
      
    class WhenProperty
      
      def initialize(parent,name, &block)
       @tag = nil
       @name = name
       @references = nil
       @block = block
       @parent = parent
      end
      attr:tag,true
      attr:type,true
      attr:value,true
      attr_reader:name
      attr_accessor:block
      
      def &
        return @parent
      end
      
      def bind(n)
        @tag = n
      end
      
      def not=(value,ref=nil)
        if ref && ref == :%
          raise 'Using \'not=\' for references is not yet supported'
          set_block do |x,y| x != y end
          references value
        else        
          set_block do |s| s != value end
        end
        
      end
      def set_block(&block)
        @block = block
      end
      private:set_block
      
      def references(refs)
        @references = refs
      end
      
      def to_atom(pattern_tags)
        unless @tag
          @tag = GeneratedTag.new
        end
        if @references
          @references = [@references] unless @references.kind_of?(Array)
          i = includes_how_many(@references, pattern_tags.keys)
          if i == 0
            return Ruleby::Core::ReferenceAtom.new(@tag, @name, @references, @parent.type, &@block)
          elsif i == @references.size
            refs = @references.collect{|r| pattern_tags[r] }
            return Ruleby::Core::SelfReferenceAtom.new(@tag, @name, refs, @parent.type, &@block)
          else
            raise 'Referencing self AND other patterns in the same atom is not yet supported'
          end
        else  
          return Ruleby::Core::PropertyAtom.new(@tag, @name, @parent.type, &@block)
        end
      end
      
      private
      def includes_how_many(list1, list2)
        i = 0
        list2.each do |a|
          i += 1 if list1.include?(a)
        end
        return i
      end
    end

  end
end