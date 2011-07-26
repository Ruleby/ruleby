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

require 'core/atoms'
require 'core/patterns'
require 'core/utils'
require 'core/nodes'

module Ruleby
  module Core
  
  # An action is a wrapper for a code block that will be executed if a rule is
  # satisfied.  
  class Action    
    attr_accessor :priority
    attr_accessor :name
    attr_reader   :matches
    attr_reader   :proc
    
    def initialize(&block)
      @name = nil
      @proc = Proc.new(&block) if block_given?
      @priority = 0
    end
            
    def fire(match, engine=nil)
      if @proc.arity == 2
        @proc.call(match, engine)
      else
        @proc.call(match)
      end
    end 
       
    def ==(a2)
      return @name == a2.name
    end    
  end   
 
  # An activation is an action/match pair that is executed if a rule is matched.
  # It also contains metadata that can be used for conflict resolution if two 
  # rules are satisfied by the same fact.
  class Activation      
    attr_reader   :action, :match
    attr_accessor :counter, :used
    
    def initialize(action, match, counter=0)
      @action = action
      @match = match
      @match.recency.sort!
      @match.recency.reverse!
      @counter = counter
      @used = false
    end   
    
    def fire(engine=nil)
      @used = true
      @action.fire @match, engine
    end
    
    def <=>(a2)          
      return @counter <=> a2.counter if @counter != a2.counter
      return @action.priority <=> a2.action.priority if @action.priority != a2.action.priority           

      # NOTE in order for this to work, the array must be reverse sorted
      i = 0; while @match.recency[i] == a2.match.recency[i] && i < @match.recency.size-1 && i < a2.match.recency.size-1 
        i += 1
      end
      @match.recency[i] <=> a2.match.recency[i]
    end
    
    def ==(a2)
      a2 != nil && @action == a2.action && @match == a2.match
    end

    def modify(match)
      @match = match
      # should we update recency, too? 
    end
    
    def to_s
      return "[#{@action.name}-#{object_id}|#{@counter}|#{@action.priority}|#{@match.recency.join(',')}|#{@match.to_s}] "
    end
  end
 
  class Rule  
    attr_accessor :pattern
    attr_reader   :action, :name, :priority   
    
    def initialize(name, pattern=nil, action=nil, priority=0) 
      @name = name
      @pattern = pattern
      @action = action  
      @priority = priority    
    end
    
    def priority=(p)
      @priority = p
      @action.priority = @priority
    end    
  end
  
  # A fact is an object that is stored in working memory.  The rules in the 
  # system will either look for the existence or absence of particular facts.
  class Fact      
    attr :recency, true
    attr_reader :object
    
    def initialize(object)
      @object = object
    end
       
    def id
      return object.object_id
    end
    
    def ==(fact)
      if fact.is_a? Fact
        fact != nil && fact.id == id
      else
        fact != nil && fact.object_id == id
      end
    end
    
    def to_s
      "[Fact |#{@recency}|#{@object.to_s}]"
    end
  end
  
  # A conflict resolver is used to order activations that become active at the 
  # same time.  The default implementation sorts the agenda based on the 
  # properties of the activation.
  class RulebyConflictResolver   
    def resolve(agenda) 
      return agenda.sort
    end    
  end
  
  # The working memory is a container for all the facts in the system.  The
  # inference engine will compare these facts with the rules to produce some
  # outcomes.  
  class WorkingMemory
    attr_reader :facts
    
    def initialize
      @recency = 0
      @facts = Array.new
    end
    
    def each_fact
      @facts.each do |f|
        yield(f)
      end
    end
    
    def assert_fact(fact)
      raise 'The fact asserted cannot be nil!' if fact.object.nil?
      fact.recency = @recency
      @recency += 1
      @facts.push fact
      return fact
    end

    def retract_fact(fact)
      i = @facts.index(fact)
      raise 'The fact to remove does not exist!' unless i
      existing_fact = @facts[i]
      @facts.delete_at(i)
      return existing_fact
    end
    
    def print
      puts 'WORKING MEMORY:'
      @facts.each do |fact|
        puts " #{fact.object} - #{fact.id} - #{fact.recency}"
      end
    end
  end

  class Error
    attr_reader :type, :level, :details

    def initialize(type, level, details={})
      @type = type
      @details = details
      @level = level
    end
  end

  # This is the core class of the library.  A new rule engine is created by 
  # instantiating it.  Each rule engine has one inference engine, one rule set
  # and one working memory.
  class Engine        
    
    def initialize(wm=WorkingMemory.new,cr=RulebyConflictResolver.new)
      @root = nil
      @working_memory = wm
      @conflict_resolver = cr
      @wm_altered = false
      assert InitialFact.new
    end
    
    def facts
      @working_memory.facts.collect{|f| f.object}.select{|f| !f.is_a?(InitialFact)}
    end

    # This method id called to add a new fact to working memory
    def assert(object,&block)
      @wm_altered = true
      fact_helper(object,:plus,&block)
    end

    # This method is called to remove an existing fact from working memory
    def retract(object,&block)
      @wm_altered = true
      fact_helper(object,:minus,&block)
      object
    end

    # This method is called to alter an existing fact.  It is essentially a 
    # retract followed by an assert.
    def modify(object,&block)
      retract(object,&block)
      assert(object,&block)
    end
    
    def retrieve(c)
      facts.select {|f| f.kind_of?(c)}
    end
    
    # This method adds a new rule to the system.
    def assert_rule(rule)         
      if @root == nil
        @root = RootNode.new(@working_memory) 
        @root.reset_counter
      end
      @root.assert_rule rule
    end
    
    # This method executes the activations that were generated by the rules
    # that match facts in working memory.
    def match(agenda=nil, used_agenda=[])      
      if @root
        @root.reset_counter
        agenda = @root.matches unless agenda 
        while (agenda.length > 0)
          agenda = @conflict_resolver.resolve agenda            
          activation = agenda.pop   
          used_agenda.push activation     
          activation.fire self   
          if @wm_altered          
            agenda = @root.matches(false)    
            @root.increment_counter
            @wm_altered = false
          end
        end
      end
    end

    def errors
      @root.nil? ? [] : @root.errors
    end

    def clear_errors
      @root.clear_errors if @root
    end

    def print
      @working_memory.print
      @root.print
    end 
    
    private 
      def fact_helper(object, sign=:plus)
        f = Core::Fact.new object
        yield f if block_given?
        sign==:plus ? assert_fact(f) : retract_fact(f)
        f
      end   
      
      def assert_fact(fact)
        wm_fact = @working_memory.assert_fact fact      
        @root.assert_fact wm_fact if @root != nil
      end

      def retract_fact(fact)
        wm_fact = @working_memory.retract_fact fact
        @root.retract_fact wm_fact if @root != nil
      end
  end  
end
end