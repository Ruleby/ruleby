require 'spec_helper'

class A

end

include Ruleby::RuleHelper

describe Ruleby::Core::Rule do

  before do
    name 'test1'
    desc 'testdesc'
    opts :priority => 1   
    @name, @desc, @opts = self.send(:pop_cur_name_desc_opts)
  end

  describe 'name' do
    it 'should have name "test1"' do
      @name.should == 'test1'
    end
  end
  describe 'desc' do
    it 'should have desc "testdesc"' do
      @desc.should == 'testdesc'
    end
  end
  describe 'opts' do 
    it 'should have opts priority => 1' do
      @opts.should == {:priority => 1}
    end
  end
end
