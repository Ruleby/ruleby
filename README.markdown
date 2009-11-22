Ruleby :: The Rule Engine for Ruby
==================================

Description
-----------
Ruleby is a rule engine written in the Ruby language. It is a system for executing a set 
of IF-THEN statements known as production rules. These rules are matched to objects using 
the forward chaining Rete algorithm. Ruleby provides an internal Domain Specific Language 
(DSL) for building the productions that make up a Ruleby program.

Version 
-------
0.6-SNAPSHOT

Release Notes
-------------
* Added support for AND and OR conditional elements in the LHS of a rule
* Added the ability to self-reference in the LHS without binding
* Fixed bug in retract_resolve on JoinNode that was causing inconsistent behavior of :not patterns.

Mailing List
------------
ruleby@googlegroups.com
