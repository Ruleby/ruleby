require 'spec_helper'

class A
  attr :value, true
  def initialize(v=nil); @value = v; end
end

class B
  attr :value1, true
  attr :value2, true
  def initialize(v1=nil, v2=nil); @value1 = v1; @value2 = v2; end
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

  def rules_with_one_pattern_and_other_conditions
    rule [:collect, A, :a, m.value == "foo"] do |v|
      assert v[:a]
      assert Success.new
    end

    rule [:collect, B, :b, m.value1 == "foo", m.value2 == "bar"] do |v|
      assert v[:b]
      assert Success.new
    end
  end

  def rules_with_one_pattern_inside_and
    rule AND([:collect, A, :a]) do |v|
      assert v[:a]
      assert Success.new
    end
  end

  def rules_with_two_collect_patterns_of_same_type
    rule [:collect, A, :a1], [:collect, A, :a2] do |v|
      assert v[:a1]
      assert v[:a2]
      assert Success.new
    end
  end

  def rules_with_two_collect_patterns_of_different_type
    rule [:collect, A, :a], [:collect, B, :b] do |v|
      assert v[:a]
      assert v[:b]
      assert Success.new
    end
  end

  def rules_with_one_pattern_and_a_not_on_right
    rule [:collect, A, :a], [:not, B] do |v|
      assert v[:a]
      assert Success.new
    end
  end

  def rules_with_one_pattern_and_a_not_on_left
    rule [:not, B], [:collect, A, :a] do |v|
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

  def rules_with_more_than_one_pattern_on_each_side
    rule [B, :b], [:collect, A, :a], [C, :c] do |v|
      assert v[:a]
      assert Success.new
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

  def rules_with_binding
    rule [:collect, A, :a], [B, :b, m.value1(:a, &c{|v1, a| a.size > 0 and a[0].object.value == v1})] do |v|
      assert Success.new
    end

    rule [:collect, A, :a], [B, :b, m.value1(:a, &c{|v1, a| a.size > 1 and a[0].object.value == v1})] do |v|
      assert Success.new
    end
  end

  def rules_with_chaining_and_binding
    rule [:collect, A, :a], [B, :b, m.value1(:a, &c{|v1, a| a.size > 0})] do |v|
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

    shared_examples_for "not patterns with [:collect, A] and [:not, B] when there is a B" do
      it "should not match" do
        s = subject.retrieve Success
        s.should_not be_nil
        s.size.should == 0
      end

      it "should match once B is retracted" do
        a = subject.retrieve B
        subject.retract a[0]

        subject.match

        s = subject.retrieve Success
        s.size.should == 1
        a = subject.retrieve A
        a.size.should == 2
      end
    end

    shared_examples_for "one :collect A rule and one A" do
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

    shared_examples_for "one :collect A rule and two As" do
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

        it_should_behave_like "one :collect A rule and one A"
      end

      context "with more than one A" do
        before do
          subject.assert A.new
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "one :collect A rule and two As"
      end
    end

    context "as one pattern and other conditions" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_one_pattern_and_other_conditions
        end
      end

      context "with one A('foo')" do
        before do
          subject.assert A.new("foo")
          subject.match
        end

        it_should_behave_like "one :collect A rule and one A"
      end

      context "with more than one A('foo')" do
        before do
          subject.assert A.new("foo")
          subject.assert A.new("foo")
          subject.match
        end

        it_should_behave_like "one :collect A rule and two As"
      end

      context "with one A('foo') and one A(nil)" do
        before do
          subject.assert A.new("foo")
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
      end

      context "with more than one A('foo') and one A(nil)" do
        before do
          subject.assert A.new("foo")
          subject.assert A.new("foo")
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
      end

      context "with one A(nil)" do
        before do
          subject.assert A.new
          subject.match
        end

        it "should not succeed" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 0
        end
      end

      context "with one B(foo,nil)" do
        before do
          subject.assert B.new("foo")
          subject.match
        end

        it "should not succeed" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 0
        end
      end

      context "with one B(foo,bar)" do
        before do
          subject.assert B.new("foo", "bar")
          subject.match
        end

        it "should not succeed" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1
        end
      end

      context "with one B(foo,bar) and one B(foo,nil)" do
        before do
          subject.assert B.new("foo", "bar")
          subject.assert B.new("foo", "bar")
          subject.assert B.new("foo")
          subject.match
        end

        it "should succeed" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 1

          a = s[0]
          a.size.should == 2
          a[0].object.class.should == B
          a[1].object.class.should == B
        end
      end
    end

    context "as one pattern inside AND" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_one_pattern_inside_and
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "one :collect A rule and one A"
      end

      context "with more than one A" do
        before do
          subject.assert A.new
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "one :collect A rule and two As"
      end
    end

    context "as two patterns of same type" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_two_collect_patterns_of_same_type
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.match
        end

        it "should match" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1

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
    end

    context "as two patterns of different type" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_two_collect_patterns_of_different_type
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.match
        end

        it "should not match" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 0
        end
      end

      context "with one A and one B" do
        before do
          subject.assert A.new
          subject.assert B.new
          subject.match
        end

        it "should not match" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 1

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 2

          classes = []

          a = s[0]
          a.size.should == 1
          classes << a[0].object.class

          a = s[1]
          a.size.should == 1
          classes << a[0].object.class

          classes.should include(A, B)
        end
      end
    end

    context "as one pattern and a not on left" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_one_pattern_and_a_not_on_left
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "one :collect A rule and one A"
      end

      context "with more than one A" do
        before do
          subject.assert A.new
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "one :collect A rule and two As"
      end

      context "with more than one A and a B" do
        before do
          subject.assert A.new
          subject.assert A.new
          subject.assert B.new
          subject.match
        end

        it_should_behave_like "not patterns with [:collect, A] and [:not, B] when there is a B"
      end

      context "with more than one A and a B" do
        before do
          subject.assert B.new
          subject.assert A.new
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "not patterns with [:collect, A] and [:not, B] when there is a B"
      end
    end

    context "as one pattern and a not on right" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_one_pattern_and_a_not_on_right
        end
      end

      context "with one A" do
        before do
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "one :collect A rule and one A"
      end

      context "with more than one A" do
        before do
          subject.assert A.new
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "one :collect A rule and two As"
      end

      context "with more than one A's first and a B" do
        before do
          subject.assert A.new
          subject.assert A.new
          subject.assert B.new
          subject.match
        end

        it_should_behave_like "not patterns with [:collect, A] and [:not, B] when there is a B"
      end

      context "with more than one A and a B first" do
        before do
          subject.assert B.new
          subject.assert A.new
          subject.assert A.new
          subject.match
        end

        it_should_behave_like "not patterns with [:collect, A] and [:not, B] when there is a B"
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
          subject.assert A.new
          subject.assert B.new
          subject.assert A.new
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.should_not be_nil
          s.size.should == 2

          s = subject.retrieve Array
          s.should_not be_nil
          s.size.should == 2 # one array for each rule

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

    context "as patterns on each side" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_more_than_one_pattern_on_each_side
        end
      end

      context "with one A" do
        context "and no C" do
          before do
            subject.assert A.new
            subject.assert B.new
            subject.match
          end

          it "should retrieve Success" do
            s = subject.retrieve Success
            s.should_not be_nil
            s.size.should == 0
          end
        end

        context "and all other facts" do
          before do
            subject.assert A.new
            subject.assert B.new
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
      end

      context "with more than one A" do
        before do
          subject.assert A.new
          subject.assert B.new
          subject.assert C.new
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

        it "should retract A without error" do
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

        it "should retract B without error" do
          s = subject.retrieve Success
          subject.retract s[0]
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

        it "should retract C without error" do
          s = subject.retrieve Success
          subject.retract s[0]
          b = subject.retrieve C
          subject.retract b[0]

          subject.match

          s = subject.retrieve Success
          s.size.should == 0
          a = subject.retrieve A
          a.size.should == 2
          b = subject.retrieve C
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

          a = s[0]
          a.size.should == 5
          a[0].object.class.should == A
        end
      end
    end

    context "with rule binding" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_binding
        end
      end

      context "with one A and one B that have == values" do
        before do
          a = A.new
          a.value = 1
          b = B.new
          b.value1 = 1
          subject.assert b
          subject.assert a
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.size.should == 1
        end
      end

      context "with one A and one B that have == values asserted in reverse order" do
        before do
          a = A.new
          a.value = 1
          b = B.new
          b.value1 = 1
          subject.assert a
          subject.assert b
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.size.should == 1
        end
      end

      context "with one A and one B that have != values" do
        before do
          a = A.new
          a.value = 1
          b = B.new
          b.value1 = 42
          subject.assert a
          subject.assert b
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.size.should == 0
        end
      end

      context "with one A and one B that have != values" do
        before do
          a1 = A.new
          a1.value = 1
          b1 = B.new
          b1.value1 = 1
          a2 = A.new
          a2.value = 1
          subject.assert a1
          subject.assert b1
          subject.assert a2
          subject.match
        end

        it "should retrieve Success" do
          s = subject.retrieve Success
          s.size.should == 2
        end
      end
    end


    context "as rule chain with binding" do
      subject do
        engine :engine do |e|
          CollectRulebook.new(e).rules_with_chaining_and_binding
        end
      end

      context "with one B and one C" do
        before do
          subject.assert B.new
          subject.assert C.new
          subject.match
        end

        it "should retrieve Success" do
          subject.retrieve(Success).size.should == 1
        end
      end

      context "with many C's and two B" do
        before do
          subject.assert C.new
          subject.assert C.new
          subject.assert B.new
          subject.assert C.new
          subject.assert C.new
          subject.assert C.new
          subject.assert B.new
          subject.match
        end

        it "should retrieve Success" do
          subject.retrieve(Success).size.should == 2

          s = subject.retrieve Array
          s.size.should == 2

          a = s[0]
          a.size.should == 5
          a.each {|o| o.object.class.should == A }

          a = s[1]
          a.size.should == 5
          a.each {|o| o.object.class.should == A }
        end
      end
    end
  end
end