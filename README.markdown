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
0.7

Release Notes
-------------
+  Fixed a bug that was causing Exceptions in RHS condition blocks to be swallowed
+  Fixed bug related to the OR and AND functions
+  Issue that causes incorrect behavior for bindings when using OR function not fixed

Mailing List
------------
ruleby@googlegroups.com
