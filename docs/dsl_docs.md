# The Ruleby DSL

This document is a description of the new Ruleby DSL called Magnum.  

## The basics

Let's say you want to create a rule that matches all Message facts.  It would look like this:

    rule [Message] do 
      # do stuff...
    end

Now let's say you want to have access to the Message fact in the right-hand-side.  You can bind it to a symbol like this:

    rule [Message, :m] do |vars|
      puts vars[:m].text
      # do stuff...
    end

But maybe you only want the rule match messages that were created by a particular person.  You can added conditions to the rule's pattern like this:

    rule [Message, :m, where{ self.author == "Joe Kutner" }] do |vars|
      # do stuff
    end

The reference to `self` in the `where` clause represents the fact object that the rule is being tested against (but don't try to manipulated it, it's really just a proxy).

We can add multiple conditions to one where clause by additional statements like this:

    rule [Message, :m, where{ 
            self.type == :HELLO
            self.author == "Joe Kutner" }] do |vars|
      # do stuff
    end

After adding several conditions, you may find that the `self` prefix is too verbose.  If so, you can do this:


    rule [Message, :m, where{ |m|
            m.type == :HELLO
            m.author == "Joe Kutner" }] do |vars|
      # do stuff
    end

Now let's say you don't want a specific author; you just want one of the authors that is also a fact.  We can do this by adding an additional pattern to the rule and binding the two pattern together, like this:

    rule [Author, :a], 
         [Message, :m, where{ (self.author == ??) << :a }] do |vars|
      # do stuff
    end

Let's break this example down.  First, we've added an Author pattern to the rule that binds the fact it matches to the `:a` symbol.  Then, it sets a condition on the Message pattern where it's `author` must be equal to the value of `:a`.

Next, let's add some more complex conditions to the pattern. 

## Function conditions

We can apply generic functions that return true or false to a fact like this

    rule [Message, :m, where{ |m|
            m.lambda(arg1, arg2) {|fact, arg1, arg2| 
                fact.value < arg1 and fact.value > arg2 }) }] do |vars|
      # do stuff
    end

## Using Boolean Operators

We can can use the OR operator to conjoin two patterns:

    rule OR([Message, :m, where{ self.author == "Joe Kutner" }], 
            [Author, :a, where{ self.name == "Joe Kutner" }]) do |vars|
      # do stuff
    end

## Using Bindings

We can bind values to symbols and then apply conditions to those symbols. 

    rule [Author, :a, where{ self.name >> :name }],
         [Message, :m, where{ (self.author == ??) << :name }] do |vars|
      # do stuff
    end

We can even bind the value that we compared against another binding:

    rule [Author, :a, where{ self.name >> :name }],
         [Message, :m, where{ ((self.author.not== ??) << :name) >> :msg_author }] do |vars|
      puts "Message author is: #{vars[:msg_author]}"
      # do stuff
    end

We can also use bindings with function conditions:

    rule [Author, :a, where{ self.name >> :name }],
         [Message, :m, where{ 
            self.author(&lambda{|fact, name| fact.matches(name) }) << :name }] do |vars|
      # do stuff
    end

