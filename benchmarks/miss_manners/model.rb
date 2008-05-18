# This file is part of the Ruleby project (http://ruleby.org)
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# LICENSE.txt file.
# 
# Copyright (c) 2007 Joe Kutner and Matt Smith. All rights reserved.
#
# * Authors: Joe Kutner, Matt Smith
#

module MissManners

  class Chosen
    def initialize(id,guestName,hobby)
      @id = id
      @guestName = guestName
      @hobby = hobby
    end
    attr_reader :id, :guestName, :hobby
    def to_s
      "{Chosen id=#{@id}, name=#{@guestName}, hobbies=#{@hobby}}"
    end
  end
  
  class Context
    START_UP      = 0
    ASSIGN_SEATS  = 1
    MAKE_PATH     = 2
    CHECK_DONE    = 3
    PRINT_RESULTS = 4
    STATE_STRINGS = ["START_UP","ASSIGN_SEATS","MAKE_PATH","CHECK_DONE","PRINT_RESULTS"]
    def initialize(state)
      if state == :start
        @state = START_UP
      else
        raise "Context #{state.to_s} does not exist for Context Enum"
      end
    end
    attr :state, true
    def string_value
      return STATE_STRINGS[@state]
    end
    def is_state(state)
      return @state == state
    end
    def to_s
      return "[Context state=" + string_value.to_s + "]";
    end
  end
  
  class Count
    def initialize(value)
      @value = value
    end
    attr :value, true
    def ==(object)
      if object.object_id == self.object_id
        return true
      elsif object == nil || !(object.kind_of?(Count))
        return false
      end
      return @value == object.value;
    end
    def to_s
      return "[Count value=#{@value.to_s}]"
    end
    def to_hash
      return value.to_hash
    end
  end
  
  class Guest
    def initialize(name,sex,hobby)
      @name = name
      @sex = sex
      @hobby = hobby
    end
    attr_reader :name,:sex,:hobby
    def to_s
      return "[Guest name=" + @name.to_s + ", sex=" + @sex.to_s + ", hobbies=" + @hobby.to_s + "]";
    end
  end
  
  class Hobby
    @stringH1 = "h1"
    @stringH2 = "h2"
    @stringH3 = "h3"
    @stringH4 = "h4"
    @stringH5 = "h5"
    HOBBY_STRINGS = [@stringH1,@stringH2,@stringH3,@stringH4,@stringH5]  
    def initialize(hobby)
      @hobbyIndex = hobby-1
      @hobby = HOBBY_STRINGS[@hobbyIndex]
    end
    H1 = Hobby.new(1)
    H2 = Hobby.new(2)
    H3 = Hobby.new(3)
    H4 = Hobby.new(4)
    H5 = Hobby.new(5)
    attr_reader :hobby
    def resolve(hobby)
      if @stringH1 == hobby 
        return H1
      elsif @stringH2 == hobby 
        return H2
      elsif @stringH3 == hobby 
        return H3
      elsif @stringH4 == hobby 
        return H4
      elsif @stringH5 == hobby  
        return H5
      else 
        raise "Hobby '" + @hobby.to_s + "' does not exist for Hobby Enum" 
      end
    end
    def to_hash
      return @hobbyIndex.to_hash
    end
    def to_s
      return @hobby
    end
  end
  
  class LastSeat
    def initialize(seat)
      @seat = seat
    end
    attr_reader :seat
    def to_s
      return "[LastSeat seat=#{@seat.to_s}]"
    end
  end
  
  class Path
    def initialize(id,seat,guestName)
      @id = id
      @guestName = guestName
      @seat = seat
    end
    attr_reader :id, :guestName, :seat
    def to_s
      "[Path id=#{@id.to_s}, name=#{@guestName.to_s}, seat=#{@seat.to_s}]"
    end
  end
  
  class Seating
    def initialize(id,pid,path,leftSeat,leftGuestName,rightSeat,rightGuestName)
      @id = id
      @pid = pid
      @path = path
      @leftSeat = leftSeat
      @leftGuestName = leftGuestName
      @rightSeat = rightSeat
      @rightGuestName = rightGuestName
    end
    attr :path, true
    attr_reader :id,:pid,:leftSeat,:leftGuestName,:rightSeat,:rightGuestName
    def to_s
      return "[Seating id=#{@id.to_s} , pid=#{pid.to_s} , pathDone=#{@path.to_s} , leftSeat=#{@leftSeat.to_s}, leftGuestName=#{@leftGuestName.to_s}, rightSeat=#{@rightSeat.to_s}, rightGuestName=#{@rightGuestName.to_s}]";
    end
  end
  
  class Sex  
    STRING_M = 'm'
    STRING_F = 'f'
    SEX_LIST = [ STRING_M, STRING_F ]
    def initialize(sex)
      @sex = sex
    end
    M = Sex.new( 0 )
    F = Sex.new( 1 )
    def sex
      return SEX_LIST[sex]
    end
    def resolve(sex) 
      if STRING_M == sex 
        return M
      elsif STRING_F == sex 
        return F
      else 
        raise "Sex '#{@sex.to_s}' does not exist for Sex Enum" 
      end
    end
    def to_s
      return @sex.to_s
    end
    def to_hash
      return @sex.to_hash
    end
  end

end