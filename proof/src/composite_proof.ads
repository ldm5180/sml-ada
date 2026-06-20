pragma Ada_2022;

--  A concrete Sml.Machines.Composite instance so gnatprove verifies the
--  child-first dispatch free of run-time errors (propagating only the parent's
--  Unhandled_Event).  The child here is a trivial "never handles" stand-in --
--  enough to analyse Process's body; real delegation is exercised by the tests.

with Sml.Machines;
with Sml.Machines.Composite;

package Composite_Proof
  with SPARK_Mode
is

   type State is (Off, On);
   type Event_Kind is (E_Power);

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event)
   is null;

   procedure No_Child
     (Ctx : in out Context; Evt : Event; Handled : out Boolean);

   package SM is new
     Sml.Machines
       (State       => State,
        Event_Kind  => Event_Kind,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);

   package Comp is new SM.Composite (Process_Child => No_Child);

   function Run return State
   with Post => Run'Result = Off;

end Composite_Proof;
