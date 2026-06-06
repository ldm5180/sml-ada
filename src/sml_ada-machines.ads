--  State machine with payload-carrying events, named guards and actions, and
--  an extended-state Context.  Guard/Action names are dispatched by the
--  Evaluate/Execute formals, keeping the transition table pure data and the
--  engine inlinable and SPARK-friendly.

generic
   type State is (<>);
   type Event_Kind is (<>);
   type Event (<>) is private;
   type Context is limited private;
   type Guard_Kind is (<>);
   type Action_Kind is (<>);
   with function Kind_Of (E : Event) return Event_Kind;
   with
     function Evaluate
       (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;
   with procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event);
   Debug : Boolean := False;
   --  When False every Trace call below is statically eliminated.
   with procedure Trace (Message : String) is null;
package Sml_Ada.Machines with SPARK_Mode is

   type Transition is record
      From   : State;
      On     : Event_Kind;
      Guard  : Guard_Kind;
      Action : Action_Kind;
      To     : State;
   end record;

   type Transition_Table is array (Positive range <>) of Transition;

   type Completeness is (Partial, Total);
   type Unhandled_Policy is (Stay, Raise_Error, Go_To_Default);

   Unhandled_Event  : exception;
   Incomplete_Table : exception;

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

   type Machine (Count : Natural) is record
      Current      : State;
      On_Unhandled : Unhandled_Policy;
      Default      : State;
      Table        : Transition_Table (1 .. Count);
   end record;

   function State_Of (M : Machine) return State
   is (M.Current);

end Sml_Ada.Machines;
