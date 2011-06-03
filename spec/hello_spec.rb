require 'spec_helper'

class HelloFact
  attr :value, true
  def initialize(v=nil); @value = v; end
end

include Ruleby

class HelloRulebook < Rulebook
  def rules
    rule [HelloFact, :h] do
      assert Success.new
    end
  end
end

describe Ruleby::Core::Engine do
  subject do
    engine :engine do |e|
      HelloRulebook.new(e).rules
    end
  end

  before do
    subject.assert HelloFact.new
    subject.match
  end

  it "should have matched" do
    subject.errors.should == []
    subject.retrieve(Success).size.should == 1
  end
end