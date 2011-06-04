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

include Ruleby

class Customer
  def initialize(name,subscription)
    @name = name
    @subscription = subscription
  end
  attr_reader :name,:subscription
  def to_s
    return '[Customer ' + @name.to_s + ' : ' + @subscription.to_s + ']';
  end
end

class Ticket
  def initialize(customer)
    @customer = customer
    @status = :New
  end
  attr :status, true
  attr_reader :customer
  def to_s
    return '[Ticket ' + @customer.to_s + ' : ' + @status.to_s + ']';
  end
end

# This example is used in JBoss-Rules to demonstrate durations and the use of
# custom DSL.  We are simply using it here to demonstrate another example.
class TroubleTicketRulebook < Rulebook
  def rules
  
    # This is uses the letigre syntax... but we can mix and match syntaxes in 
    # the same rule set.
    rule :New_Ticket, {:priority => 10}, # :duration => 10},
      [Customer, :c],
      [Ticket, :ticket, {m.customer => :c}, m.status == :New] do |vars|
        puts 'New : ' + vars[:ticket].to_s
    end
    
    # Now we are using the ferrari syntax.  The rule method can detect which 
    # syntax we are using, and compile accordingly.
    rule :Silver_Priority, #{:duration => 3000},
      [Customer, :customer, m.subscription == 'Silver'],
      [Ticket,:ticket, m.customer == b(:customer), m.status == :New] do |vars|
        vars[:ticket].status = :Escalate
        modify vars[:ticket]
    end
    
    rule :Gold_Priority, #{:duration => 1000},
      [Customer, :customer, m.subscription == 'Gold'],
      [Ticket,:ticket, m.customer == b(:customer), m.status == :New] do |vars|
        vars[:ticket].status = :Escalate
        modify vars[:ticket]
    end
    
    rule :Platinum_Priority,
      [Customer, :customer, m.subscription == 'Platinum'],
      [Ticket,:ticket, m.customer == b(:customer), m.status == :New] do |vars|
        vars[:ticket].status = :Escalate
        modify vars[:ticket]
    end
    
    rule :Escalate,
      [Customer, :c],
      [Ticket, :ticket, {m.customer => :c}, m.status == :Escalate] do |vars|
        puts 'Email : ' + vars[:ticket].to_s    
    end
    
    rule :Done,
      [Customer, :c],
      [Ticket, :ticket, {m.customer => :c}, m.status == :Done] do |vars|
        puts 'Done : ' + vars[:ticket].to_s
    end
  end
end

# FACTS

a = Customer.new('A', 'Gold')
b = Customer.new('B', 'Platinum')
c = Customer.new('C', 'Silver')
d = Customer.new('D', 'Silver')

t1 = Ticket.new(a)
t2 = Ticket.new(b)
t3 = Ticket.new(c)
t4 = Ticket.new(d)

engine :engine do |e|
  TroubleTicketRulebook.new(e).rules
  e.assert a
  e.assert b
  e.assert c
  e.assert d
  e.assert t1
  e.assert t2
  e.assert t3
  e.assert t4
  e.match
end