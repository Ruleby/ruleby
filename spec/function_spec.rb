require 'spec_helper'

class FuncFact
  attr :value, true
  attr :times, true
  def initialize(v=nil); @value = v; @times = 0; end
end

include Ruleby

class FunctionsRulebook < Rulebook
  def rules_with_simple_function
    rule [FuncFact, :a, where {|f|
        f.lambda("b") {|a, b| b == "b"}
    }] do |v|
      assert Success.new
    end
  end

  def rules_with_function_testing_self(arg)
    rule [FuncFact, :a, where {|f|
        f.lambda(arg) {|a, b| a.value == b}
    }] do |v|
      assert Success.new
    end
  end

  def rules_that_share_a_function
    func = lambda {|a, b| a.times += 1; b == "foobar"}

    rule [FuncFact, :a, where {|f|
        self.value > 1
        f.lambda("foobar", &func)
    }] do |v|
      assert Success.new
    end

    rule [FuncFact, where {|f|
        self.value > 2
        f.lambda("foobar", &func)
    }] do |v|
      assert Success.new
    end
  end

  def rules_with_many_args_function
    rule [FuncFact, :a, where {|f|
        f.lambda(1, 2, 3, 4) {|a, b, c, d, e| b < e}
    }] do |v|
      assert Success.new
    end
  end

  def rules_with_no_args_function
    rule [FuncFact, :a, where {
        lambda {|a| !a.nil?}
    }] do |v|
      assert Success.new
    end
  end
end

describe Ruleby::Rulebook do

  describe "#f" do
    context "rules_with_simple_function" do
      subject do
        engine :engine do |e|
          FunctionsRulebook.new(e).rules_with_simple_function
        end
      end

      context "with one FuncFact" do
        before do
          subject.assert FuncFact.new
          subject.match
        end

        it "should match once" do
          r = subject.retrieve Success
          r.size.should == 1
          subject.errors.should == []
        end
      end
    end

    context "rules_with_function_testing_self(:foo)" do
      subject do
        engine :engine do |e|
          FunctionsRulebook.new(e).rules_with_function_testing_self(:foo)
        end
      end

      context "with one FuncFact" do
        before do
          subject.assert FuncFact.new(:foo)
          subject.match
        end

        it "should match once" do
          r = subject.retrieve Success
          r.size.should == 1
          subject.errors.should == []
        end
      end
    end

    context "rules_with_function_testing_self(:bar)" do
      subject do
        engine :engine do |e|
          FunctionsRulebook.new(e).rules_with_function_testing_self(:bar)
        end
      end

      context "with one FuncFact" do
        before do
          subject.assert FuncFact.new(:foo)
          subject.match
        end

        it "should not match " do
          r = subject.retrieve Success
          r.size.should == 0
          subject.errors.should == []
        end
      end
    end

    context "rules_that_share_a_function" do
      subject do
        engine :engine do |e|
          FunctionsRulebook.new(e).rules_that_share_a_function
        end
      end

      context "with one FuncFact" do
        before do
          @f = FuncFact.new(3)
          subject.assert @f
          subject.match
        end

        it "should match, node should be shared, function should be evaled once" do
          r = subject.retrieve Success
          r.size.should == 2
          subject.errors.should == []

          @f.times.should == 1

          subject.retract r[0]
          subject.retract r[1]
          subject.retract @f
          subject.match

          r = subject.retrieve Success
          r.size.should == 0
          subject.errors.should == []

          subject.assert @f
          subject.match

          r = subject.retrieve Success
          r.size.should == 2
          subject.errors.should == []

          @f.times.should == 2
        end
      end
    end

    context "rules_with_many_args_function" do
      subject do
        engine :engine do |e|
          FunctionsRulebook.new(e).rules_with_many_args_function
        end
      end

      context "with one FuncFact" do
        before do
          subject.assert FuncFact.new
          subject.match
        end

        it "should match once" do
          r = subject.retrieve Success
          r.size.should == 1
          subject.errors.should == []
        end
      end
    end

    context "rules_with_no_args_function" do
      subject do
        engine :engine do |e|
          FunctionsRulebook.new(e).rules_with_no_args_function
        end
      end

      context "with one FuncFact" do
        before do
          subject.assert FuncFact.new
          subject.match
        end

        it "should match once" do
          r = subject.retrieve Success
          r.size.should == 1
          subject.errors.should == []
        end
      end
    end
  end
end
