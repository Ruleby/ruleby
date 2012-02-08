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
    name :Measles
    opts :priority => 100
    rule [Patient,:p, where { |m|
        m.name >> :n
        m.fever==:high
        m.spots==true
        m.innoculated==true
      }] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :measles)
        puts "Measles diagnosed for #{name}"  
    end
    
    name :Allergy1
    rule [Patient,:p, where {self.name >> :n; self.spots==true}],
      [:not, Diagnosis, where{|m| (m.name==??) << :n; m.diagnosis==:measles}] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :allergy)
        puts "Allergy diagnosed for #{name} from spots and lack of measles"
    end
    
    name :Allergy2
    rule [Patient,:p, where {self.name >> :n; self.rash==true}] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :allergy)
        puts "Allergy diagnosed from rash for #{name}"
    end     
    
    name :Flu
    rule [Patient,:p, where {
        self.name >> :n
        self.sore_throat==true
        self.fever {|f| f==:mild || f==:high}
      }] do |v|
        name = v[:n]
        assert Diagnosis.new(name, :flu)
        puts "Flu diagnosed for #{name}"
    end     

    name :Penicillin
    rule [Diagnosis, :d, where {self.name >> :n; self.diagnosis==:measles}] do |v|
        name = v[:n]
        assert Treatment.new(name, :penicillin)
        puts "Penicillin prescribed for #{name}"
    end  
    
    name :Allergy_pills
    rule [Diagnosis, :d, where {self.name >> :n; self.diagnosis==:allergy}] do |v|
        name = v[:n]
        assert Treatment.new(name, :allergy_shot)
        puts "Allergy shot prescribed for #{name}"
    end

    name :Bed_rest
    rule [Diagnosis, :d, where {self.name >> :n; self.diagnosis==:flu}] do |v|
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