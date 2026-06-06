--  A concrete instance so gnatprove has something to verify (it does not
--  analyse uninstantiated generics).  Proving Coin_Then_Push exercises the
--  Layer 0 engine: absence of run-time errors plus the Make/Process_Event
--  contracts chaining to the expected final state.

with Sml_Ada.State_Machines;

package Turnstile_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event is (Coin, Push);

   function Next (From : State; On : Event) return State
   is (case From is
         when Locked   => (if On = Coin then Unlocked else Locked),
         when Unlocked => (if On = Push then Locked else Unlocked));

   package Turnstile is new
     Sml_Ada.State_Machines
       (State   => State,
        Event   => Event,
        Initial => Locked,
        Next    => Next);

   function Coin_Then_Push return State
   with Post => Coin_Then_Push'Result = Locked;

end Turnstile_Proof;
