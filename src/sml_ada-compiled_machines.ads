--  Fully-dissolved layer: you supply Step, a procedure that encodes the whole
--  transition (guards as `if`s, actions as inline statements, the next state
--  as an assignment).  Process_Event just calls Step, which GNAT inlines at
--  -O2/-O3 to a branch/jump sequence -- no transition table, no scan, no
--  indirect calls.  A Machine is a single State, so the footprint is minimal.
--
--  This trades the at-a-glance data table of Sml_Ada.Machines for Boost.SML-
--  style code generation; reach for it on hot paths or in tiny binaries.

generic
   type State is (<>);
   type Event (<>) is private;
   type Context is limited private;
   with
     procedure Step
       (Current : in out State; Ctx : in out Context; Evt : Event);
package Sml_Ada.Compiled_Machines with SPARK_Mode is

   type Machine is private;

   function Make (Initial : State) return Machine
   with Post => State_Of (Make'Result) = Initial;

   function State_Of (M : Machine) return State;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   with Inline;

private

   type Machine is record
      Current : State;
   end record;

   function State_Of (M : Machine) return State
   is (M.Current);

end Sml_Ada.Compiled_Machines;
