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

engine :engine do |e|
  File.open('sample.yml') do |f|
    YamlDsl.load_rules(f, e)
  end
  e.assert Message.new(:HELLO, 'Hello World')
  e.match
end
