require 'spec_helper'

class A
  attr :value, true
  def initialize(v=nil); @value = v; end
end

include Ruleby

class ErrorsRulebook < Rulebook
  def rules_with_method_that_doesnt_exist
    rule [A, :a, m.foobar == 'quack'] do |v|
      assert Success.new
    end
  end

  def rules_that_raise_errors
    rule [A, :a, m.value(&c{|v| raise ":(" if v == 42; true})] do |v|
      assert Success.new
    end
  end

end

describe Ruleby::Core::Engine do

  describe "#errors" do
    context "rules_with_method_that_doesnt_exist" do
      subject do
        engine :engine do |e|
          ErrorsRulebook.new(e).rules_with_method_that_doesnt_exist
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.match
        end

        it "should accumulate an error" do
          r = subject.retrieve Success
          r.size.should == 0

          errors = subject.errors
          errors.should_not be_nil
          errors.size.should == 1
          errors[0].type.should == :no_method
          errors[0].details[:method].should == :foobar
          errors[0].details[:object].should match /#<A:(.+)>/
          subject.clear_errors

          subject.errors.should == []
        end
      end

      context "with one A that quacks" do
        before do
          a = A.new

          # define a method on the instance (not on the class)
          def a.foobar
            "quack"
          end

          subject.assert a
          subject.assert A.new
          subject.match
        end

        it "should accumulate one error" do
          r = subject.retrieve Success
          r.size.should == 1

          errors = subject.errors
          errors.should_not be_nil
          errors.size.should == 1
          errors[0].type.should == :no_method
          errors[0].details[:method].should == :foobar
          errors[0].details[:object].should match /#<A:(.+)>/
          subject.clear_errors
        end
      end
    end


    context "rules_that_raise_errors" do
      subject do
        engine :engine do |e|
          ErrorsRulebook.new(e).rules_that_raise_errors
        end
      end

      context "with one A where value==42" do
        before do
          a = A.new
          a.value = 42
          subject.assert a
          subject.match
        end

        it "should accumulate an error" do
          r = subject.retrieve Success
          r.size.should == 0

          errors = subject.errors
          errors.should_not be_nil
          errors.size.should == 1
          errors[0].type.should == :proc_call
          errors[0].details[:message].should == ':('
          errors[0].details[:object].should match /#<A:(.+)>/
          errors[0].details[:method].should == :value
          errors[0].details[:value].should == "42"
          subject.clear_errors
        end
      end

      context "with one A where value==42, and one A where value==0" do
        before do
          a1 = A.new
          a1.value = 42

          a2 = A.new
          a2.value = 0

          subject.assert a1
          subject.assert a2
          subject.match
        end

        it "should accumulate one error" do
          r = subject.retrieve Success
          r.size.should == 1

          errors = subject.errors
          errors.should_not be_nil
          errors.size.should == 1
          errors[0].type.should == :proc_call
          errors[0].details[:message].should == ':('
          errors[0].details[:object].should match /#<A:(.+)>/
          errors[0].details[:method].should == :value
          errors[0].details[:value].should == "42"
          subject.clear_errors
        end
      end
    end
  end
end