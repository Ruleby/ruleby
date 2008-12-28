require 'rubygems'
require 'treetop'

require '../../lib/ruleby'
require '../../lib/dsl/treetop/treetop_helper'
module Ruleby
  module TreeTopDsl
    def self.load_rules(rules, engine)
          parser = RulebyParser.new
          ast = parser.parse(rules)
          if ast
            rs = ast.get_rules
            puts 'success'
            rs.each do |r|
              puts r.inspect
              engine.assert_rule(r)
            end
          else 
            puts ast
            puts 'failure'
          end
    end
  end
end
`tt ../../lib/dsl/treetop/tt_dsl.treetop`
require '../../lib/dsl/treetop/tt_dsl'
class Message
  
end
include Ruleby
engine :engine do |e|
  Ruleby::TreeTopDsl.load_rules(IO.read('../../examples/treetop/hello.ruleby'), e)
  e.assert Message.new
  e.match   
end

