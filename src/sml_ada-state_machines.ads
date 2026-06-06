--  Minimal state machine: enumeration states and events and a Next function,
--  with no guards or actions.  See Sml_Ada.Machines for the richer layer.

generic
   type State is (<>);
   type Event is (<>);
   Initial : State;
   with function Next (From : State; On : Event) return State;
package Sml_Ada.State_Machines with Preelaborate, SPARK_Mode is

   type Machine is private;

   function Make return Machine
   with Post => State_Of (Make'Result) = Initial;

   function State_Of (M : Machine) return State;

   procedure Process_Event (M : in out Machine; On : Event)
   with Post => State_Of (M) = Next (State_Of (M)'Old, On);

private

   type Machine is record
      Current : State := Initial;
   end record;

   function State_Of (M : Machine) return State
   is (M.Current);

end Sml_Ada.State_Machines;
