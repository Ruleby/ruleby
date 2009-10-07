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
    
    def initialize(&block)
      @name = nil
      @proc = Proc.new(&block) if block_given?
      @priority = 0
    end
            
    def fire(match)
      @proc.call(match)        
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
    
    def fire()
      @used = true
      @action.fire @match
    end
    
    def <=>(a2)          
      return @counter <=> a2.counter if @counter != a2.counter
      return @action.priority <=> a2.action.priority if @action.priority != a2.action.priority           

      # NOTE in order for this to work, the array must be reverse sorted
      i = 0; while @match.recency[i] == a2.match.recency[i] && i < @match.recency.size-1 && i < a2.match.recency.size-1 
        i += 1
      end
      return @match.recency[i] <=> a2.match.recency[i]
    end
    
    def ==(a2)
      return a2 != nil && @action == a2.action && @match == a2.match
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
    attr :token, true
    attr :recency, true    
    attr_reader :object
    
    def initialize(object, token)
      @token = token      
      @object = object
    end
       
    def id
      return object.object_id
    end
    
    def ==(fact)
      return fact != nil && fact.id == id
    end
    
    def to_s
      return "[Fact |#{@recency}|#{@object.to_s}]"
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
      raise 'The fact asserted cannot be nil!' unless fact.object
      if (fact.token == :plus)
        fact.recency = @recency
        @recency += 1
        @facts.push fact
        return fact
      else #if (fact.token == :minus)  
        i = @facts.index(fact)
        raise 'The fact to remove does not exist!' unless i
        existing_fact = @facts[i]
        @facts.delete_at(i)
        existing_fact.token = fact.token
        return existing_fact
      end
    end
    
    def print
      puts 'WORKING MEMORY:'
      @facts.each do |fact|
        puts " #{fact.object} - #{fact.id} - #{fact.recency}"
      end
    end
  end

  # This is the core class of the library.  A new rule engine is create by 
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
      @working_memory.facts.collect{|f| f.object}
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
      @root = RootNode.new(@working_memory) if @root == nil
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
          activation.fire   
          if @wm_altered          
            agenda = @root.matches(false)    
            @root.increment_counter
            @wm_altered = false
          end
        end
      end
    end
    
    def print
      @working_memory.print
      @root.print
    end 
    
    private 
      def fact_helper(object, sign=:plus, &block)
        f = Core::Fact.new object, sign
        yield f if block_given?
        assert_fact f
        f
      end   
      
      def assert_fact(fact)
        wm_fact = @working_memory.assert_fact fact      
        @root.assert_fact wm_fact if @root != nil
      end  
  end  
end
end