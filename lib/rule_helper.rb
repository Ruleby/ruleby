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

module Ruleby
  module RuleHelper

    def rule(*args, &block)      
      name, desc, opts = pop_cur_name_desc_opts
      name ||= GeneratedTag.new
      raise 'Must provide arguments to rule' if args.empty?      
      # r = Ruleby::Magnum::RulebookHelper.new @engine
      # r.rule name, opts, *args, &block


      rules = Ruleby::Magnum.parse_containers(args, Ruleby::Magnum::RulesContainer.new).
          build(name,opts,@engine,&block)
      rules
    end

    def where
      Ruleby::Magnum::WhereBuilder.new(&Proc.new)
    end

    def name(n)
      @cur_name = n 
    end

    def desc(d)
      @cur_desc = d 
    end

    def opts(o)
      @cur_opts = o 
    end

    def reset_class_vars
      @cur_name, @cur_desc, @cur_opts = "default", '', Hash.new
    end

    def OR(*args)
      Ruleby::Magnum::OrBuilder.new args
    end

    def AND(*args)
      Ruleby::Magnum::AndBuilder.new args
    end

    # private

    def pop_cur_name_desc_opts
      name = defined?(@cur_name) ? @cur_opts : GeneratedTag.new
      desc = defined?(@cur_desc) ? @cur_opts : ""
      opts = defined?(@cur_opts) ? @cur_opts : {}
      reset_class_vars
      return name, desc, opts.dup
    end
  end
end