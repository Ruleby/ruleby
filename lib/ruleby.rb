# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors:  Joe Kutner, Matt Smith
#

require 'core/engine'
require 'rulebook'

module Ruleby
  #helper classes for using ruleby go here
  def engine(name, &block)
    e = Core::Engine.new
    yield e if block_given?
    return e
  end
end

class String
  unless ''.respond_to?(:to_proc)
    def to_proc &block
      params = []
      expr = self
      sections = expr.split(/\s*->\s*/m)
      if sections.length > 1 then
          eval sections.reverse!.inject { |e, p| "(Proc.new { |#{p.split(/\s/).join(', ')}| #{e} })" }, block && block.binding
      elsif expr.match(/\b_\b/)
          eval "Proc.new { |_| #{expr} }", block && block.binding
      else
          leftSection = expr.match(/^\s*(?:[+*\/%&|\^\.=<>\[]|!=)/m)
          rightSection = expr.match(/[+\-*\/%&|\^\.=<>!]\s*$/m)
          if leftSection || rightSection then
              if (leftSection) then
                  params.push('$left')
                  expr = '$left' + expr
              end
              if (rightSection) then
                  params.push('$right')
                  expr = expr + '$right'
              end
          else
              self.gsub(
                  /(?:\b[A-Z]|\.[a-zA-Z_$])[a-zA-Z_$\d]*|[a-zA-Z_$][a-zA-Z_$\d]*:|self|arguments|'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/, ''
              ).scan(
                /([a-z_$][a-z_$\d]*)/i
              ) do |v|  
                params.push(v) unless params.include?(v)
              end
          end
          eval "Proc.new { |#{params.join(', ')}| #{expr} }", block && block.binding
      end
    end
  end
end