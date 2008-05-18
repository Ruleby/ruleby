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

$LOAD_PATH << File.join(File.dirname(__FILE__), '../../lib/')
require 'ruleby'
require 'model'
require 'data'
require 'rules'

include Ruleby
include MissManners

t1 = Time.new
engine :e do |e|     
  MannersRulebook.new(e).rules
  MannersData.new.guests16.each do |g|
    e.assert g
  end  
  e.assert Context.new(:start)
  e.assert Count.new(1)  
  e.match
end
t2 = Time.new
diff = t2.to_f - t1.to_f
puts diff.to_s