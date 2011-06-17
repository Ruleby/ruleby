require 'spec_helper'

class PropFact
  attr :value, true
  def initialize(v=nil); @value = v; end
end

class PropCtx

end


include Ruleby

class PropRulebook < Rulebook
  def gt_rules
    rule [PropFact, :p, m.value > 0] do
      assert Success.new
    end
  end

  def lte_rules
    rule [PropFact, :p, m.value > 42], [PropCtx, :pc] do
      # do nothing, just being here helps reproduce a bug
    end
    rule [PropFact, :p, m.value <= 42], [PropCtx, :pc] do
      assert Success.new
    end
  end
end

describe Ruleby::Core::Engine do
  describe "property gt_rules" do
    subject do
      engine :engine do |e|
        PropRulebook.new(e).gt_rules
      end
    end

    before do
      subject.assert PropFact.new(1)
      subject.match
    end

    it "should have matched" do
      subject.errors.should == []
      subject.retrieve(Success).size.should == 1
    end
  end
  describe "property lte_rules" do
    subject do
      engine :engine do |e|
        PropRulebook.new(e).lte_rules
      end
    end

    before do
      subject.assert PropCtx.new
      subject.assert PropFact.new(42)
      subject.assert PropFact.new(41)
      subject.match
    end

    it "should have matched" do
      subject.errors.should == []
      subject.retrieve(Success).size.should == 2
    end
  end
end
