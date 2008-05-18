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
  module LeTigre
    class RulebookHelper
      
      def initialize(engine, rulebook)
        @rulebook = rulebook
        @engine = engine
      end
    
      attr_reader :engine
    
      def rule(name, *args, &then_block)
        if args.empty?
          raise 'No conditions supplied.'
        end
      
        options = args[0].kind_of?(Hash) ? args.shift : {}
      
        pb = PatternParser.new @rulebook
        pattern = pb.parse args
    
        rb = RuleBuilder.new name
        
        rb.when(pattern)
        rb.then(&then_block)
        rb.priority = options[:priority] if options[:priority]
        
        @engine.assert_rule rb.build_rule
      end
    
    end
    
    class RuleBuilder
    
      def initialize(name, pattern=nil, action=nil, priority=0) 
        @name = name
        @pattern = pattern
        @action = action  
        @priority = priority    
        
        @tags = {}
        @when_counter = 0
      end   
        
      def when(pattern)
        @pattern = pattern
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
    
    class PatternParser
      @@head_error = 'Invalid type specification.'      
      @@method_error = "No #method in expression: "
    
      @@base_re  = /(For each|\w*\s*exists\??|not\??)(.*)/
      @@mode_re  = /( (is a|kind of|instance of) )(.*)/
      @@where_re = /(.*)where (.*)/      
      @@head_re  = /(\w*)( as :(.*))?/
      
      @@method_re = /#((\w|\d|\_)*)\??/
      @@bind_re   = /#:(\w*|\d*\_*)*/
      @@and_re    = /#&&/
      @@tag_re    = /(.*) as :(.*)/
      
      def initialize(rulebook)
        @rulebook = rulebook
      end
      
      def parse(lhs_strs)
        pattern = nil
        lhs_strs.each do |lhs|  
          # match the quantifier
          if lhs =~ @@base_re
            base = $1
            tail = $2
          else
            base = 'For each'
            tail = lhs
          end
          
          raise 'The \'exists\' quantifier is not yet supported.' if base =~ /exists/
          
          if tail =~ @@mode_re
            mode = :inherits
            tail = $3
          else
            mode = :equals           
          end
          
          # check if there is a where clause
          if tail =~ @@where_re
            head = $1.strip
            tail = $2
          else
            head = tail.strip
            tail = nil
          end
          
          # match the class type and tag
          if head != ''
            head =~ @@head_re            
            clazz = @rulebook.__eval__ $1
            tag = $3 ? $3.to_sym : GeneratedTag.new 
          else
            clazz = Object
            tag = GeneratedTag.new
            mode = :inherits
          end
          
          deftemplate = Core::DefTemplate.new clazz, mode
          head = Core::HeadAtom.new tag, deftemplate

          atoms = []      
          atom_strs = tail ? tail.split(@@and_re) : []
          atom_strs.each do |a|
            # BUG we also need to pass in the head_tag with atoms!
            atoms.push parse_atom(a, deftemplate, atoms)
          end        
                    
          if base =~ /not\??/
            p = mode==:inherits ? Core::NotInheritsPattern.new(head, atoms) :
                                  Core::NotPattern.new(head, atoms) 
          else 
            p = mode==:inherits ? Core::InheritsPattern.new(head, atoms) :
                                  Core::ObjectPattern.new(head, atoms) 
          end
                              
          pattern = pattern ? Core::AndPattern.new(pattern, p) : p
        end
        return pattern
      end
      
      private 
      def parse_atom(str, deftemplate, atoms)
        expression, tag = nil, nil
        if str =~ @@tag_re 
          expression, tag = $1, $2.strip.to_sym
        else
          expression, tag = str, GeneratedTag.new
        end
        
        bindings = []
        uniq_binds = []
        expression.scan(@@bind_re).each do |b|
          # HACK how can we create a truely unique variable name?
          uniq_bind = "ruleby_unique_variable_name_#{b[0]}"
          uniq_binds.push uniq_bind
          expression.sub!(/#:#{b[0]}/, uniq_bind)
          bindings.push b[0].strip.to_sym
        end      
        
        raise @@method_error + expression unless expression =~ @@method_re
        method = $1
        expression.gsub!(/##{method}/, method)      
        expression = "true" if expression.strip == method
        
        proc = "lambda {|#{method}"
          
        uniq_binds.each do |b|
          # TODO make sure 'b' is not equal to 'method' or other b's
          proc += ",#{b}"
        end
        
        proc += "| #{expression} }"
        
        block = eval proc
    
        if bindings.empty? 
          return Core::PropertyAtom.new(tag, method, deftemplate, &block)
        elsif references_self?(bindings, atoms)
          bound_methods = resolve_bindings(bindings, atoms)
          return Core::SelfReferenceAtom.new(tag, method, bound_methods, deftemplate, &block)
        else
          return Core::ReferenceAtom.new(tag, method, bindings, deftemplate, &block)
        end
      end
      
      def references_self?(bindings, atoms)
        ref_self = 0
        bindings.each do |b|
          atoms.each do |a|
            if (a.tag == b)
              ref_self += 1
            end
          end
        end
        
        if ref_self > 0 and ref_self != bindings.size
          raise 'Binding to self and another pattern in the same expression is not yet supported.'
        end
        
        return ref_self > 0
      end
      
      def resolve_bindings(bindings, atoms)
        bound_methods = []
        bindings.each do |b|
          atoms.each do |a|
            if a.tag == b
              bound_methods.push a.method
            end
          end
        end
        return bound_methods
      end
      
    end 
  end
end