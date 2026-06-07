pragma Ada_2022;

--  A concrete instance so gnatprove has something to verify (it does not
--  analyse uninstantiated generics).  It instantiates the engine and its
--  operators (Sml.Machines + Sml.Machines.Operators) for a turnstile
--  and proves the engine is free of run-time errors, plus that Make establishes
--  the initial state (its Post chains through to Run's result).

with Sml.Machines;
with Sml.Machines.Operators;

package Turnstile_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event_Kind is (E_Coin, E_Push);

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

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);

   function Run return State
   with Post => Run'Result = Locked;

end Turnstile_Proof;
