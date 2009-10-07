
class Context
  
  def initialize
    @counts = {}
    @counts.default = 0
  end
  
  def inc(key)
    @counts[key] += 1    
  end
  
  def set(key,value)
    @counts[key] = value
  end
  
  def get(key)
    @counts[key]
  end
end

class Message
  def initialize(status,message)
    @status = status
    @message = message
  end
  attr :status, true
  attr :message, true
end