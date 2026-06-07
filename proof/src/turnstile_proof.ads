pragma Ada_2022;

--  A concrete instance so gnatprove has something to verify (it does not
--  analyse uninstantiated generics).  It instantiates the DSL layer
--  (Sml_Ada.Machines + Sml_Ada.Machines.Dsl) for a turnstile and proves the
--  engine is free of run-time errors when driven, plus that Make establishes
--  the initial state (its Post chains through to Run's result).

with Sml_Ada.Machines;
with Sml_Ada.Machines.Dsl;

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
     Sml_Ada.Machines
       (State       => State,
        Event_Kind  => Event_Kind,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);

   package D is new SM.Dsl (Always => Always, Nothing => Nothing);

   function Run return State
   with Post => Run'Result = Locked;

end Turnstile_Proof;
