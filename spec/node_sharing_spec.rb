require 'spec_helper'

class NodeShareFact
  attr_reader :times

  def initialize(v=nil); @value = v; @times = 0; end

  def value
    @times += 1
    @value
  end
end

include Ruleby

class NodeShareRulebook < Rulebook
  def rules
    rule [NodeShareFact, :n, m.value == 5] do
      assert Success.new
    end

    rule [NodeShareFact, :n, m.value == 5] do
      assert Success.new
    end

    rule [NodeShareFact, :n, m.value == 6] do
      assert Success.new
    end
  end
end

describe Ruleby::Core::Engine do

  describe "node sharing" do
    subject do
      engine :engine do |e|
        NodeShareRulebook.new(e).rules
      end
    end

    before do
      @f = NodeShareFact.new(5)
      subject.assert @f
      subject.match
    end

    it "should have matched" do
      @f.times.should == 1
      subject.errors.should == []
      subject.retrieve(Success).size.should == 2
    end
  end
end