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

require 'model'

module MissManners

class MannersRulebook < Ruleby::Rulebook
  def rules
    rule :assignFirstSeat, 
      [Context,:context, m.state == Context::START_UP], 
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
    
    rule :findSeating, 
      [Context,:context, {m.state == Context::ASSIGN_SEATS => :state}],
      [Count,:count, {m.value => :countValue}],       
      [Seating,:seating, {m.path ==  true =>:p, m.id=>:seatingId, m.pid=>:seatingPid, m.rightSeat=>:seatingRightSeat,  m.rightGuestName=>:seatingRightGuestName}],
      [Guest,:g, {m.name=>:name, m.sex=>:rightGuestSex, m.hobby=>:rightGuestHobby}, m.name == b(:seatingRightGuestName)],
      [Guest,:lg, {m.name=>:leftGuestName, m.sex=>:sex, m.hobby == b(:rightGuestHobby) => :hobby}, m.sex(:rightGuestSex, &c{|s,rgs| s != rgs} )],         
      [:~,Path, m.id == b(:seatingId), m.guestName == b(:leftGuestName)],
      [:~,Chosen, m.id == b(:seatingId), m.guestName == b(:leftGuestName), m.hobby == b(:leftGuestHobby)] do |vars|         
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
    
    rule :makePath, 
      [Context,:context, {m.state == Context::MAKE_PATH => :s}],
      [Seating,:seating, {m.id=>:seatingId, m.pid=>:seatingPid, m.path == false =>:p}],
      [Path,:path, {m.guestName=>:pathGuestName, m.seat=>:pathSeat}, m.id == b(:seatingPid)],
      [:~,Path,m.id == b(:seatingId), m.guestName == b(:pathGuestName)] do |vars|
        path = Path.new(vars[:seatingId],vars[:pathSeat],vars[:pathGuestName])        
        assert path
        puts "make Path : #{path}"    
    end
    
    # NOTE We had to add the priority because Ruleby's conflict resolution strategy
    # is not robust enough.  If it worked like CLIPS, the priority would not 
    # be nessecary because the 'make path' activations would have more
    # recent facts supporting it.  This is really an error in the Miss Manners
    # benchmark, so it is not considered cheating.
    rule :pathDone, {:priority => -5},
      [Context,:context, m.state == Context::MAKE_PATH],
      [Seating,:seating, m.path == false] do |vars|
        vars[:seating].path = true
        modify vars[:seating]        
        vars[:context].state = Context::CHECK_DONE
        modify vars[:context]
        puts "path Done : #{vars[:seating]}"
    end
    
    rule :areWeDone,
      [Context,:context, m.state == Context::CHECK_DONE],
      [LastSeat,:ls, {m.seat => :lastSeat}],
      [Seating,:seating, m.rightSeat == b(:lastSeat)] do |vars|
        vars[:context].state = Context::PRINT_RESULTS
        modify vars[:context]
    end
    
    rule :continue, {:priority => -5},
      [Context,:context,m.state == Context::CHECK_DONE] do |vars|
        vars[:context].state = Context::ASSIGN_SEATS
        modify vars[:context]
    end
    
    rule :allDone,
      [Context,:context,m.state == Context::PRINT_RESULTS] do |vars|
        puts 'All done'
    end
  end
end

end