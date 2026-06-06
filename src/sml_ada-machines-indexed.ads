--  O(1) variant of Sml_Ada.Machines: the same readable transition table, but
--  Make precomputes a (State, Event_Kind) -> row lookup so Process_Event does
--  a single indexed read instead of scanning the table.
--
--  It requires at most one transition per (State, Event_Kind) cell -- Make
--  raises Duplicate_Transition otherwise -- so it suits deterministic machines
--  (a cell's guard, if it fails, falls through to the unhandled-event policy).
--  Instantiate it on a Machines instance and feed it the same table.

generic
package Sml_Ada.Machines.Indexed with SPARK_Mode is

   Duplicate_Transition : exception;

   type Machine (<>) is private;

   function State_Of (M : Machine) return State;

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Machine
   with Post => State_Of (Make'Result) = Initial;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event);

private

   type Index_Table is array (State, Event_Kind) of Natural;

   type Machine (Count : Natural) is record
      Current      : State;
      On_Unhandled : Unhandled_Policy;
      Default      : State;
      Index        : Index_Table;
      Table        : Transition_Table (1 .. Count);
   end record;

   function State_Of (M : Machine) return State
   is (M.Current);

end Sml_Ada.Machines.Indexed;
