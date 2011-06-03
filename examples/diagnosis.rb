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

$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib/')
require 'ruleby'

class Patient
  def initialize(name,fever,spots,rash,sore_throat,innoculated)
    @name = name
    @fever = fever
    @spots= spots
    @rash = rash
    @sore_throat = sore_throat
    @innoculated = innoculated
  end  
  attr:name, true
  attr:fever, true
  attr:spots, true
  attr:rash, true
  attr:sore_throat, true
  attr:innoculated, true
end

class Diagnosis
  def initialize(name,diagnosis)
    @name=name
    @diagnosis=diagnosis
  end
  attr:name,true
  attr:diagnosis,true
end

class Treatment
  def initialize(name,treatment)
    @name=name
    @treatment=treatment
  end
  attr:name,true
  attr:treatment,true  
end

class DiagnosisRulebook < Ruleby::Rulebook
  def rules
    rule :Measles, {:priority => 100},
      [Patient,:p,{m.name=>:n},m.fever==:high,m.spots==true,m.innoculated==true] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :measles)
        puts "Measles diagnosed for #{name}"  
    end
    
    rule :Allergy1,
      [Patient,:p, {m.name=>:n}, m.spots==true],
      [:not, Diagnosis, m.name==b(:n), m.diagnosis==:measles] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :allergy)
        puts "Allergy diagnosed for #{name} from spots and lack of measles"
    end
    
    rule :Allergy2,
      [Patient,:p, {m.name=>:n}, m.rash==true] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :allergy)
        puts "Allergy diagnosed from rash for #{name}"
    end     
    
    rule :Flu,
      [Patient,:p, {m.name=>:n}, m.sore_throat==true, m.fever(&c{|f| f==:mild || f==:high})] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :flu)
        puts "Flu diagnosed for #{name}"
    end     

    rule :Penicillin,
      [Diagnosis, :d, {m.name => :n}, m.diagnosis==:measles] do |v|
        name = v[:n]
        assert Treatment.new(name, :penicillin)
        puts "Penicillin prescribed for #{name}"
    end  
    
    rule :Allergy_pills,
      [Diagnosis, :d, {m.name => :n}, m.diagnosis==:allergy] do |v|
        name = v[:n]
        assert Treatment.new(name, :allergy_shot)
        puts "Allergy shot prescribed for #{name}"
    end

    rule :Bed_rest,
      [Diagnosis, :d, {m.name => :n}, m.diagnosis==:flu] do |v|
        name = v[:n]
        assert Treatment.new(name, :bed_rest)
        puts "Bed rest prescribed for #{name}"
    end
  end
end

include Ruleby

engine :engine do |e|
  
  DiagnosisRulebook.new e do |r|
    r.rules
  end

  e.assert Patient.new('Fred',:none,true,false,false,false)
  e.assert Patient.new('Joe',:high,false,false,true,false)
  e.assert Patient.new('Bob',:high,true,false,false,true)
  e.assert Patient.new('Tom',:none,false,true,false,false)
  
  e.match

# expect this output:
#  Measles diagnosed for Bob
#  Penicillin prescribed for Bob
#  Allergy diagnosed from rash for Tom
#  Allergy shot prescribed for Tom
#  Flu diagnosed for Joe
#  Bed rest prescribed for Joe
#  Allergy diagnosed for Fred from spots and lack of measles
#  Allergy shot prescribed for Fred

end