pragma Ada_2022;

--  A concrete Sml.Simple_Machines instance (a turnstile, whose Coin/Push events
--  carry no payload) so gnatprove verifies the no-payload layer: the engine is
--  free of run-time errors and Make establishes the initial state.

with Sml.Simple_Machines;

package Simple_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event is (Coin, Push);
   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event)
   is null;

   package SM is new
     Sml.Simple_Machines
       (State       => State,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Evaluate    => Evaluate,
        Execute     => Execute);

   function Run return State
   with Post => Run'Result = Locked;

end Simple_Proof;
