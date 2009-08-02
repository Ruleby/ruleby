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

class Message
  def initialize(status,message)
    @status = status
    @message = message
  end
  attr :status, true
  attr :message, true
end

class HelloWorldRulebook < Rulebook
  def rules
    rule [Message, :m, m.status == :HELLO] do |v|
      puts v[:m].message
      v[:m].message = "Goodbye world"
      v[:m].status = :GOODBYE
      modify v[:m]
    end
    
    rule [Message, :m, m.status == :GOODBYE] do |v| 
      puts v[:m].message 
    end       
  end
end

engine :engine do |e|
  HelloWorldRulebook.new(e).rules
  e.assert Message.new(:HELLO, 'Hello World')
  e.match
end