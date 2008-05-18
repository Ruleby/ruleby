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

$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib/')
require 'ruleby'
require 'model'

include Ruleby

class TestRulebook < Rulebook
  def rules(n)
    (0..n).each do |index|
      rule "Rule-#{index}".to_sym, 
        [Account, 
          method.status == 'standard', 
          method.title == 'mr', 
          method.account_id == "acc#{index}"] do |vars|
#          puts "rule #{index} fired"
      end
    end
  end
end

def run_benchmark(rules, facts)
  puts "running benchmark for: #{rules} rules and #{facts} facts"
  
  t1 = Time.new
  engine :engine do |e|   
    TestRulebook.new(e).rules(rules)
    
    t2 = Time.new
    diff = t2.to_f - t1.to_f
    puts 'time to create rule set: ' + diff.to_s
    for k in (0..facts)
      e.assert Account.new('standard', 'mr', ('acc'+k.to_s))
    end
  
    t3 = Time.new
    diff = t3.to_f - t2.to_f
    puts 'time to assert facts: ' + diff.to_s
    e.match
  
    t4 = Time.new
    diff = t4.to_f - t3.to_f
    puts 'time to run agenda: ' + diff.to_s
  end
end

run_benchmark(5, 500)
puts '-------'
run_benchmark(50, 500)
puts '-------'
run_benchmark(500, 500)
