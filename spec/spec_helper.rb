require 'ruleby'
#require 'rspec'

class Success
  attr :status, true
  def initialize(status=nil)
    @status = status
  end
end