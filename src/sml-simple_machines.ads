--  No-payload convenience layer over Sml.Machines.  When events carry no data,
--  the event *is* its own kind, so there is no variant record to write and no
--  Kind_Of to supply: instantiate this with the event enumeration directly and
--  get the same Machine, transition table and Process_Event.
--
--     package M is new Sml.Simple_Machines
--       (State, Event, Context, Guard_Kind, Action_Kind,
--        Evaluate, Execute);
--     use M;
--     Table : constant Transition_Table :=
--       [(Locked,   Coin, Always, Nothing, Unlocked),
--        (Unlocked, Push, Always, Nothing, Locked)];
--
--  Everything is a renaming or subtype of the underlying Sml.Machines
--  instance, so it carries the same SPARK contracts at no run-time cost.

with Sml.Machines;

generic
   type State is (<>);
   type Event is (<>);
   type Context is limited private;
   type Guard_Kind is (<>);
   type Action_Kind is (<>);
   with
     function Evaluate
       (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;
   with procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event);
package Sml.Simple_Machines with SPARK_Mode is

   --  A payload-free event already is its own kind.
   function Kind_Of (E : Event) return Event
   is (E);

   package Engine is new
     Sml.Machines
       (State       => State,
        Event_Kind  => Event,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);

   --  Re-export the engine's API so callers never name the inner instance.
   subtype Transition is Engine.Transition;
   subtype Transition_Table is Engine.Transition_Table;
   subtype Machine is Engine.Machine;
   subtype Completeness is Engine.Completeness;
   subtype Unhandled_Policy is Engine.Unhandled_Policy;

   Partial       : constant Completeness := Engine.Partial;
   Total         : constant Completeness := Engine.Total;
   Stay          : constant Unhandled_Policy := Engine.Stay;
   Raise_Error   : constant Unhandled_Policy := Engine.Raise_Error;
   Go_To_Default : constant Unhandled_Policy := Engine.Go_To_Default;

   Unhandled_Event  : exception renames Engine.Unhandled_Event;
   Incomplete_Table : exception renames Engine.Incomplete_Table;

   function State_Of (M : Machine) return State renames Engine.State_Of;

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Machine
   renames Engine.Make;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   renames Engine.Process_Event;

end Sml.Simple_Machines;
