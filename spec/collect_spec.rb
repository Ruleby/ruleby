require 'spec_helper'

class A

end

class B

end

class C

end

class C
  
end

include Ruleby

class CollectRulebook < Rulebook
  def rules_with_one_pattern
    rule [:collect, A, :a] do |v|
      assert v[:a]
      assert Success.new
    end
  end

  def rules_with_more_than_one_pattern
    rule [:collect, A, :a], [B, :b] do |v|
      assert v[:a]
      assert Success.new(:right)
    end

    rule [B, :b], [:collect, A, :a] do |v|
      assert v[:a]
      assert Success.new(:left)
    end
  end

  def rules_with_chaining
    rule [:collect, A, :a] do |v|
      assert v[:a]
      assert Success.new
    end

    rule [C, :c] do |v|
      assert A.new
    end
  end
end

describe Ruleby::Core::Engine do

  describe ":collect" do
    context "as one pattern" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_one_pattern
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 1

          a = s[0]
          a.size.should == 1
          a[0].object.class.should == A
        end

        it "should retract without error" do
          s = subject.retrieve Success
          s.size.should == 1
          subject.retract s[0]

          a = subject.retrieve A
          a.size.should == 1
          subject.retract a[0]

          subject.match

          s = subject.retrieve Success
          s.size.should == 0
          a = subject.retrieve A
          a.size.should == 0
        end
      end

      context "with more than one A" do
        before do
          subject.assert A.new
          subject.assert A.new
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 1

          a = s[0]
          a.size.should == 2
          a[0].object.class.should == A
          a[1].object.class.should == A
        end

        it "should retract without error" do
          s = subject.retrieve Success
          subject.retract s[0]
          a = subject.retrieve A
          subject.retract a[0]

          subject.match

          s = subject.retrieve Success
          s.size.should == 1
          a = subject.retrieve A
          a.size.should == 1

          s = subject.retrieve Success
          subject.retract s[0]
          a = subject.retrieve A
          subject.retract a[0]

          subject.match

          s = subject.retrieve Success
          s.size.should == 0
          a = subject.retrieve A
          a.size.should == 0
        end
      end
    end

    context "as two patterns" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_more_than_one_pattern
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.assert B.new
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 2

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 2

          a = s[0]
          a.size.should == 1
          a[0].object.class.should == A

          a = s[1]
          a.size.should == 1
          a[0].object.class.should == A
        end
      end

      context "with more than one A" do
        before do
#          subject.assert A.new
#          subject.assert A.new
#          subject.assert B.new
#          subject.match
        end

        it "should retrieve Success" do
          pending("Can't join to collect patterns yet")
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 2

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 2

          a = s[0]
          a.size.should == 2
          a[0].object.class.should == A
          a[1].object.class.should == A

          a = s[1]
          a.size.should == 2
          a[0].object.class.should == A
          a[1].object.class.should == A
        end

        it "should retract A without error" do
          pending("Can't join to collect patterns yet")
          s = subject.retrieve Success
          subject.retract s[0]
          subject.retract s[1]
          a = subject.retrieve A
          subject.retract a[0]

          subject.match

          s = subject.retrieve Success
          s.size.should == 2
          a = subject.retrieve A
          a.size.should == 1

          s = subject.retrieve Success
          subject.retract s[0]
          subject.retract s[1]
          a = subject.retrieve A
          subject.retract a[0]

          subject.match

          s = subject.retrieve Success
          s.size.should == 0
          a = subject.retrieve A
          a.size.should == 0
        end

        it "should retract B without error" do
          pending("Can't join to collect patterns yet")
          s = subject.retrieve Success
          subject.retract s[0]
          subject.retract s[1]
          b = subject.retrieve B
          subject.retract b[0]

          subject.match

          s = subject.retrieve Success
          s.size.should == 0
          a = subject.retrieve A
          a.size.should == 2
          b = subject.retrieve B
          b.size.should == 0
        end
      end
    end

    context "as rule chain" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_chaining
        end
      end

      context "with one C" do
        before do
          subject.assert C.new
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 1

          a = s[0]
          a.size.should == 1
          a[0].object.class.should == A
        end
      end

      context "with many C's" do
        before do
          subject.assert C.new
          subject.assert C.new
          subject.assert C.new
          subject.assert C.new
          subject.assert C.new
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 1

          puts "Array.id = #{s[0].id}"
          a = s[0]
          a.size.should == 5
          a[0].object.class.should == A
        end
      end
    end
  end
end