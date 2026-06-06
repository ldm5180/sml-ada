--  Code generator: reads a transition table (the single source of truth) and
--  emits Ada/Graphviz for it.  Instantiate it on a Machines instance.
--
--  Put_Compiled_* emit a per-machine package whose Process_Event is a baked
--  `case` (state -> event -> guarded action -> next state).  Because the table
--  is baked in as code, GNAT dissolves the dispatch to branches at -O2/-O3 --
--  the same codegen as a hand-written Compiled machine, but generated from the
--  readable table.  The emitted unit `with`s your definitions package and
--  calls its Kind_Of/Evaluate/Execute (so the guard/action behaviour is not
--  duplicated).
--
--  Put_Dot emits a Graphviz state diagram from the same table.

with Ada.Text_IO;

generic
package Sml_Ada.Machines.Codegen with SPARK_Mode => Off is

   procedure Put_Dot
     (File    : Ada.Text_IO.File_Type;
      Table   : Transition_Table;
      Initial : State;
      Name    : String := "machine");

   procedure Put_Compiled_Spec
     (File : Ada.Text_IO.File_Type; Defs_Unit : String; Unit : String);

   procedure Put_Compiled_Body
     (File      : Ada.Text_IO.File_Type;
      Table     : Transition_Table;
      Defs_Unit : String;
      Unit      : String);

end Sml_Ada.Machines.Codegen;
