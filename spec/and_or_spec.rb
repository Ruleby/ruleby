require 'spec_helper'

class AndOrFact
  attr :value, true
  def initialize(v=nil); @value = v; end
end

class AndOrFact2
  attr :value, true
  def initialize(v=nil); @value = v; end
end

include Ruleby

class AndOrRulebook < Rulebook
  def rules
    rule AND(
             OR([AndOrFact, m.value > 0]),
             OR(
                 OR([AndOrFact, m.value == 1]),
                 AND(
                     AND([AndOrFact, m.value < 1]),
                     OR([AndOrFact, m.value == nil], [:not, AndOrFact])))) do
      assert Success.new
    end

#    rule [AndOrFact, m.value > 0],
#         OR(
#             [AndOrFact, m.value == 1],
#             AND(
#                 [AndOrFact, m.value < 1],
#                 OR([AndOrFact, m.value == nil], [:not, AndOrFact]))) do
#      assert Success.new
#    end
  end

  def rules2
    rule OR(AND(OR(OR([AndOrFact, m.value == 1])))) do |v|
      assert Success.new
    end
  end

  def rules3
    rule OR([AndOrFact, m.value == 1], [AndOrFact, m.value == 2], [AndOrFact, m.value == 3]), [AndOrFact, m.value == 4] do |v|
      assert Success.new
    end
  end

  def rules4
    rule AND([AndOrFact, :a, m.value == 1], [AndOrFact2, :a2, m.value == 2]) do |v|
      raise "nil" if v[:a].nil?
      raise "nil" if v[:a2].nil?
      assert Success.new
    end
  end

  def rules5
    rule OR(AND([AndOrFact, :a, {m.value == 1 => :x}], [AndOrFact2, m.value == b(:x)])) do |v|
      assert Success.new
    end
  end
end

describe Ruleby::Core::Engine do
#  describe "AND/OR" do
    context "crazy AND/OR rules" do
      subject do
        engine :engine do |e|
          AndOrRulebook.new(e).rules
        end
      end

      before do
        subject.assert AndOrFact.new(1)
        subject.match
      end

      it "should have matched" do
        subject.errors.should == []
        subject.retrieve(Success).size.should == 1
      end
    end

    context "nested AND/OR rule" do
      subject do
        engine :engine do |e|
          AndOrRulebook.new(e).rules2
        end
      end

      before do
        subject.assert AndOrFact.new(1)
        subject.match
      end

      it "should have matched" do
        subject.errors.should == []
        subject.retrieve(Success).size.should == 1
      end
    end

    context "multi OR rule" do
      subject do
        engine :engine do |e|
          AndOrRulebook.new(e).rules3
        end
      end

      context "with one 1 and one 4" do
        before do
          subject.assert AndOrFact.new(1)
          subject.assert AndOrFact.new(4)
          subject.match
        end

        it "should have matched" do
          subject.errors.should == []
          subject.retrieve(Success).size.should == 1
        end
      end
    end

    context "nested AND/OR rule" do
      subject do
        engine :engine do |e|
          AndOrRulebook.new(e).rules4
        end
      end

      before do
        subject.assert AndOrFact.new(1)
        subject.assert AndOrFact2.new(2)
        subject.match
      end

      it "should have matched" do
        subject.errors.should == []
        subject.retrieve(Success).size.should == 1
      end
    end

    context "nested AND/OR rule" do
      subject do
        engine :engine do |e|
          AndOrRulebook.new(e).rules5
        end
      end

      before do
        subject.assert AndOrFact.new(1)
        subject.assert AndOrFact2.new(1)
        subject.match
      end

      it "should have matched" do
        subject.errors.should == []
        subject.retrieve(Success).size.should == 1
      end
    end
#  end
end