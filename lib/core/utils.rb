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
    
    # This class is used as a unique fact that is assert to an engine's working memory
    # immediately after creation.  This fact is used mainly when a NotPattern is put
    # at the begining of a rule.  This allows it to join the 'not' to something tangible.
    class InitialFact
      
    end
    
    # Appearently Ruby doesn't have any kind of Exception chaining.  So this class will have
    # fill the gap for Ruleby.  
    class ProcessInvocationError < StandardError
      def initialize(root_cause)
        @root_cause = root_cause
      end
      
      def backtrace
        @root_cause.backtrace
      end
      
      def inspect
        @root_cause.inspect
      end
      
      def to_s
        @root_cause.to_s
      end
    end
  
    # This class is a wrapper for the context under which the network executes for
    # for a given fact.  It is essentially a wrapper for a fact and a partial
    # match.
    class MatchContext
  
      attr_reader:fact
      attr_reader:match
    
      def initialize(fact,mr)
        @fact = fact      
        @match = mr  
      end
    
      def to_s
        return @match.to_s
      end
    
      def ==(t)
        return t && @fact == t.fact && @match == t.match
      end
    end
    
    # This class represents a partial match.  It contains the variables, values,
    # and some metadata about the match.  For the most part, this metadata is used
    # during conflict resolution.
    class MatchResult    
      # TODO this class needs to be cleaned up so that we don't have a bunch of
      # properties.  Instead, maybe it sould have a list of facts.    
    
      attr :variables, true
      attr :is_match, true
      attr :fact_hash, true
      attr :recency, true
    
      def initialize(variables=Hash.new,is_match=false,fact_hash={},recency=[])
        @variables = variables      
      
        # a list of recencies of the facts that this matchresult depends on.
        @recency = recency
      
        # notes where this match result is from a NotPattern or ObjectPattern
        # TODO this isn't really needed anymore.  how can we get rid of it?
        @is_match = is_match 
      
        # a hash of fact.ids that each tag corresponds to
        @fact_hash = fact_hash 
      end
    
      def []=(sym, object)
        @variables[sym] = object
      end
    
      def [](sym)
         return @variables[sym]
      end
    
      def fact_ids
        return fact_hash.values.uniq
      end
    
      def ==(match)           
        return match != nil && @variables == match.variables && @is_match == match.is_match && @fact_hash == match.fact_hash
      end
    
      def key?(m)
        return @variables.key?(m)
      end
    
      def keys
        return @variables.keys
      end
    
      def update(mr)
        @recency = @recency | mr.recency
        @is_match = mr.is_match
        @variables = @variables.update mr.variables      
        @fact_hash = @fact_hash.update mr.fact_hash      
        return self
      end
    
      def dup     
        dup_mr = MatchResult.new
        dup_mr.recency = @recency.clone
        dup_mr.is_match = @is_match
        dup_mr.variables = @variables.clone
        dup_mr.fact_hash = @fact_hash.clone       
        return dup_mr
      end
    
      def merge!(mr)
        return update(mr)
      end
    
      def merge(mr)
        new_mr = MatchResult.new
        new_mr.recency = @recency | mr.recency
        new_mr.is_match = mr.is_match
        new_mr.variables = @variables.merge mr.variables 
        new_mr.fact_hash = @fact_hash.merge mr.fact_hash    
        return new_mr
      end
    
      def clear
        @variables = {}
        @fact_hash = {}
        @recency = []
      end
    
      def delete(tag)
        @variables.delete(tag)
        @fact_hash.delete(tag)
      end
    
      def to_s
        s = '#MatchResult('
        s = s + 'f)(' unless @is_match
        s = s + object_id.to_s+')('
        @variables.each do |key,value|
          s += "#{key}=#{value}/#{@fact_hash[key]}, "
        end
        return s + ")"
      end
    end
  
    # This class is used when we need to have a Hash where keys and values are 
    # mapped many-to-many.  This class allows for quick access of both key and 
    # value.  It is similar to Multimap in C++ standard lib.
    # This thing is a mess (and barely works). It needs to be refactored.
    class MultiHash
      def initialize(key=nil, values=[])
        @i = 0
        clear
        if key
          @keys = {key => []} 
          values.each do |v|
            xref = generate_xref()
            xref_list = @keys[key]
            xref_list.push xref
            @keys[key] = xref_list
            @values = {xref => v}
            @backward_hash = {xref => [key]}
          end
        end
      end
    
      def empty?
        return @keys.empty?
      end
    
      def rehash
        @keys.rehash
        @values.rehash
        @backward_hash.rehash
      end
    
      def value?(mr)
        @values.value?(mr)
      end
    
      def clear
        @keys = {}
        @values = {}
        @backward_hash = {}
      end
    
      def values_by_id(id)
        xrefs = @keys[id]
        values = []
        if xrefs
          xrefs.each do |k|
            values.push @values[k]
          end
        else
          #???
        end
        return values
      end
    
      def each_key
        @keys.each_key do |key|
          yield(key)
        end
      end
    
      def has_key?(key)
        return @keys.has_key?(key)
      end
    
      def key?(key)
        return has_key?(key)
      end
    
      def +(dh)
        # TODO this can be faster
        new_dh = dh.dup
        dh.concat self.dup
        return new_dh
      end
     
      def add(ids,val)
        xref = generate_xref()      
        ids.each do |id|
          xref_list = @keys[id]
          xref_list = [] if xref_list == @keys.default
          xref_list.push xref             
          @keys[id] = xref_list  
        end       
        @values[xref] = val    
        @backward_hash[xref] = ids
      end
    
      # DEPRECATED
      # WARN this method adds a value to the MultiHash only if it is unique.  It
      # can be a fairly costly operation, and should be avoided.  We only 
      # implemented this as part of a hack to get things working early on.
      def add_uniq(ids,val)
        xref = generate_xref()
        exist_list = []
        ids.each do |id|
          xref_list = @keys[id]
          if xref_list != @keys.default           
            xref_list.each do |existing_xref|  
              existing_val = @values[existing_xref] 
              if existing_val 
                if val == existing_val                        
                  xref = existing_xref 
                  exist_list.push id
                  break
                end
              else
                # HACK there shouldn't be any xrefs like this in the
                # hash to being with.  Why are they there?
                xref_list.delete(existing_xref)
                @keys[id] = xref_list
              end
            end         
          end             
        end   
        add_list = ids - exist_list   
        add_list.each do |id|
          xref_list = @keys[id]
          xref_list = [] if xref_list == @keys.default
          xref_list.push xref             
          @keys[id] = xref_list  
        end            
        @values[xref] = val if exist_list.empty?
        b_list = @backward_hash[xref]
        if b_list
          @backward_hash[xref] = b_list | ids
        else
          @backward_hash[xref] = ids
        end
      end
        
      def each
        @values.each do |xref,val|
          ids = @backward_hash[xref]        
          yield(ids,val)
        end
      end
    
      def each_internal
        @values.each do |xref,val|
          ids = @backward_hash[xref]
          yield(ids,xref,val)
        end      
      end
      private:each_internal
    
      def concat(multi_hash)
        multi_hash.each do |ids,val|
          add(ids,val)
        end
      end
    
      # DEPRECATED
      # WARN see comments in add_uniq
      def concat_uniq(double_hash)
        double_hash.each do |ids,val|
          add_uniq(ids,val)
        end
      end
    
      def default
        return @values.default
      end
        
      def remove(id)      
        xref_list = @keys.delete(id)
        if xref_list != @keys.default
          removed_values = []
          xref_list.each do |xref|
            value = @values.delete(xref)
            removed_values.push value
            id_list = @backward_hash.delete(xref)
            id_list.each do |next_id|
              remove_internal(next_id,xref) if next_id != id
            end
          end
          return removed_values
        else
  #        puts 'WARN: tried to remove from MultiHash where id does not exist'        
          return default
        end
      end
    
      def remove_internal(id,xref)
        xref_list = @keys[id]
        if xref_list # BUG this shouldn't be nil!
          xref_list.delete(xref) 
          if xref_list.empty?
            @keys.delete(id)
          else             
            @keys[id] = xref_list
          end
        end
      end
      private:remove_internal
    
      def remove_by_xref(ids,xref)
        ids.each do |id|
          xref_list = @keys[id]
          xref_list.delete(xref) 
          if xref_list.empty?
            @keys.delete(id)
          else             
            @keys[id] = xref_list
          end
        end
        @values.delete(xref)
        @backward_hash.delete(xref)
      end
      private:remove_by_xref
    
      def delete_if
        @values.delete_if do |xref,v|  
          if yield(v)
            id_list = @backward_hash.delete(xref)
            id_list.each do |next_id|
              remove_internal(next_id,xref)
            end
            true
          else
            false
          end
        end
      end
    
      def values
        return @values.values
      end
    
      def keys
        return @keys.keys
      end
    
      def dup
        dup_mc = MultiHash.new
        each do |ids,v|
          dup_mc.add ids, v.dup
        end
        return dup_mc      
      end
    
      def generate_xref()
        @i = @i + 1
        return @i
      end
      private:generate_xref
    
      # This method is for testing.  It ensures that all the Hash's
      # and Array's are in order, and not corrupted (ex. some key points
      # to a xref that does not exist in the match_results Hash).
      def valid?
        @keys.each do |id,xrefs|
  #        xref_list = @keys[id]
  #        if xref_list != @keys.default
  #          xref_list.each do |xref|
  #            id_list = @backward_hash[xref]
  #            unless id_list
  #              puts 'yup' 
  #              return false
  #            end
  #          end
  #        end
          xrefs.each do |xref|
            count = 0
            xrefs.each do |xref2|
              if xref == xref2 
                count = count + 1
                if count > 1
                  puts '(0) Duplicate xrefs in entry for keys' 
                  return false
                end
              end
            end
        
            mr = @match_results[xref] 
            if mr == @match_results.default
              puts '(1) Missing entry in @match_results for xref' 
              return false
            end
          
  #          @match_results.each do |mr_xref,other_mr|
  #            if other_mr == mr && mr_xref != xref
  #              puts '(1a) Duplicate entry in @match_results'
  #              return false
  #            end
  #          end
          
            id_list = @backward_hash[xref]
            if id_list == @backward_hash.default
              puts '(2) Missing entry in backward_hash for xref'
              return false
            end
          
            if id_list.index(id) == nil
              puts '(3) Entry in backward_hash is missing id'
              return false
            end
                    
            id_list.each do |ref_id|
              unless ref_id == id
                ref_xref_list = @keys[ref_id]
                if ref_xref_list == @keys.default
                  puts '(4) Missing entry in keys for backward_hash id'
                  puts "#{id},#{mr},#{xref},#{ref_id}"
                  return false
                end
              
                if ref_xref_list.index(xref) == nil                
                  puts '(5) Entry in keys is missing xref'
                  puts "#{id},#{mr},#{xref},#{ref_id}"
                  return false
                end
              end
            end
          end
        end           
        return true
      end
      private:valid?
     
      def ==(dh)
        # TODO need to implement this
        return super
      end
    end
  end
end