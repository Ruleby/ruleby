require 'spec_helper'

class A

end

include Ruleby

class FerrariRulebook < Rulebook
  def rules
    rule [A] do |v|
      assert Success.new
    end
  end
end

describe Ruleby::Core::Engine do

  subject do
    engine :engine do |e|
      FerrariRulebook.new(e).rules
    end
  end

  describe "simple case" do
    context "with one A" do
      before do
        subject.assert A.new
        subject.match
      end

      it "should retrieve Success" do
        s = subject.retrieve Success
        s.should_not be_nil
        s.size.should == 1
      end
    end
  end
end