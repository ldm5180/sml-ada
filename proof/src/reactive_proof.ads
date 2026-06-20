pragma Ada_2022;

--  A concrete Sml.Machines.Reactive instance so gnatprove verifies the
--  run-to-completion loop free of run-time errors (and propagating only
--  Unhandled_Event).  Run only exercises Make, as elsewhere.

with Sml.Machines;
with Sml.Machines.Reactive;

package Reactive_Proof
  with SPARK_Mode
is

   type State is (Idle, Dialing, Connected);
   type Event_Kind is (E_Dial, E_Connect);

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

   function Has_Entry_Event (S : State) return Boolean
   is (S = Dialing);

   function Entry_Event (S : State) return Event
   is ((Kind => E_Connect));

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

   package RC is new
     SM.Reactive
       (Has_Entry_Event => Has_Entry_Event,
        Entry_Event     => Entry_Event);

   function Run return State
   with Post => Run'Result = Idle;

end Reactive_Proof;
