pragma Ada_2022;

--  A concrete Sml.Machines.Deferring instance so gnatprove verifies the queue:
--  Post and the internal drain are proved free of run-time errors (and Post
--  propagates only Deferral_Overflow).  Run only exercises Make.

with Sml.Machines;
with Sml.Machines.Deferring;

package Deferring_Proof
  with SPARK_Mode
is

   type State is (Stopped, Playing, Paused);
   type Event_Kind is (E_Play, E_Pause, E_Stop);

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

   function Deferred (S : State; E : Event_Kind) return Boolean
   is (S = Stopped and then E = E_Pause);

   function Rebuild (E : Event_Kind) return Event
   is ((Kind => E));

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

   package Def is new SM.Deferring (Deferred => Deferred, Rebuild => Rebuild);

   function Run return State
   with Post => Run'Result = Stopped;

end Deferring_Proof;
