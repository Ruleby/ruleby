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

require './model.rb'

module MissManners

class MannersRulebook < Ruleby::Rulebook
  def rules
    name :assignFirstSeat
    rule [Context,:context, where{self.state == Context::START_UP}], 
      [Guest,:guest],
      [Count,:count] do |vars|         
        guestName = vars[:guest].name        
        seating =  Seating.new(vars[:count].value,1,true,1,guestName,1,guestName)
        assert seating        
        path = Path.new(vars[:count].value, 1, guestName)
        assert path
        retract vars[:count]
        vars[:count].value = vars[:count].value + 1         
        assert vars[:count]
	      puts "assign first seat :  #{seating.to_s} : #{path.to_s}"
        vars[:context].state = Context::ASSIGN_SEATS        
        modify vars[:context]  
    end
    
    name :findSeating
    rule [Context,:context, where{(self.state == Context::ASSIGN_SEATS) >> :state}],
      [Count,:count, where{self.value >> :countValue}],       
      [Seating,:seating, where{ |m|
          (m.path == true)>>:p
          m.id>>:seatingId
          m.pid>>:seatingPid
          m.rightSeat>>:seatingRightSeat
          m.rightGuestName>>:seatingRightGuestName}],
      [Guest,:g, where { |m|
          m.name >> :name
          m.sex >> :rightGuestSex
          m.hobby >> :rightGuestHobby
          (m.name == ??) << :seatingRightGuestName}],
      [Guest,:lg, where{ |m| 
          m.name >> :leftGuestName
          m.sex >> :sex
          ((m.hobby == ??) << :rightGuestHobby) >> :hobby
          (m.sex.not== ??) << :rightGuestSex}],         
      [:~,Path, where { |m|
          (m.id == ??) << :seatingId
          (m.guestName == ??) << :leftGuestName}],
      [:~,Chosen, where { |m| 
          (m.id == ??) << :seatingId
          (m.guestName == ??) << :leftGuestName
          (m.hobby == ??) << :leftGuestHobby}] do |vars|         
        rightSeat = vars[:seatingRightSeat]
        seatId = vars[:seatingId]
        countValue = vars[:count].value               
        seating = Seating.new(countValue,seatId,false,rightSeat,vars[:seatingRightGuestName],rightSeat+1,vars[:leftGuestName])        
        path = Path.new(countValue,rightSeat+1,vars[:leftGuestName])
        chosen = Chosen.new(seatId, vars[:leftGuestName], vars[:rightGuestHobby] )     
  	    puts "find seating : #{seating} : #{path} : #{chosen}"
  	    assert seating 
  	    assert path
  	    assert chosen
        vars[:count].value = countValue + 1
        modify vars[:count]
        vars[:context].state = Context::MAKE_PATH
        modify vars[:context]    
    end
    
    name :makePath
    rule [Context,:context, where {|m| (m.state == Context::MAKE_PATH) >> :s}],
      [Seating,:seating, where { |m|
          m.id >> :seatingId
          m.pid >> :seatingPid
          (m.path == false) >> :p}],
      [Path,:path, where { |m| 
          m.guestName >> :pathGuestName
          m.seat >> :pathSeat
          (m.id == ??) << :seatingPid}],
      [:~,Path, where {|m| 
          (m.id == ??) << :seatingId
          (m.guestName == ??) << :pathGuestName}] do |vars|
        path = Path.new(vars[:seatingId],vars[:pathSeat],vars[:pathGuestName])        
        assert path
        puts "make Path : #{path}"    
    end
    
    # NOTE We had to add the priority because Ruleby's conflict resolution strategy
    # is not robust enough.  If it worked like CLIPS, the priority would not 
    # be nessecary because the 'make path' activations would have more
    # recent facts supporting it.  This is really an error in the Miss Manners
    # benchmark, so it is not considered cheating.
    name :pathDone
    opts :priority => -5
    rule [Context,:context, where {self.state == Context::MAKE_PATH}],
      [Seating,:seating, where{self.path == false}] do |vars|
        vars[:seating].path = true
        modify vars[:seating]        
        vars[:context].state = Context::CHECK_DONE
        modify vars[:context]
        puts "path Done : #{vars[:seating]}"
    end
    
    name :areWeDone
    rule [Context,:context, where{self.state == Context::CHECK_DONE}],
      [LastSeat,:ls, where{self.seat >> :lastSeat}],
      [Seating,:seating, where{(self.rightSeat == ??) << :lastSeat}] do |vars|
        vars[:context].state = Context::PRINT_RESULTS
        modify vars[:context]
    end
    
    name :continue
    opts :priority => -5
    rule [Context,:context, where{self.state == Context::CHECK_DONE}] do |vars|
        vars[:context].state = Context::ASSIGN_SEATS
        modify vars[:context]
    end
    
    name :allDone
    rule [Context,:context, where{self.state == Context::PRINT_RESULTS}] do |vars|
        puts 'All done'
    end
  end
end

end