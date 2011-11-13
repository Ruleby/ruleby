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