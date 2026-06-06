--  Generic finite state machine.
--
--  States and events are enumeration (discrete) types and the transition
--  logic is supplied at instantiation through the formal function Next.
--  Because Next is fixed when the package is instantiated, the compiler can
--  inline it, and a Machine value holds nothing but its current state --
--  keeping the run-time footprint to a single enumeration, in the spirit of
--  Boost.SML.
--
--  Example (a turnstile):
--
--     type State is (Locked, Unlocked);
--     type Event is (Coin, Push);
--
--     function Next (From : State; On : Event) return State is
--       (case From is
--          when Locked   => (if On = Coin then Unlocked else Locked),
--          when Unlocked => (if On = Push then Locked   else Unlocked));
--
--     package Turnstile is new Sml_Ada.State_Machines
--       (State, Event, Initial => Locked, Next => Next);

generic
   type State is (<>);
   type Event is (<>);
   Initial : State;
   with function Next (From : State; On : Event) return State;
package Sml_Ada.State_Machines with Preelaborate is

   type Machine is private;
   --  Carries the current state only.

   function Make return Machine
   with Post => State_Of (Make'Result) = Initial;
   --  A fresh machine sitting in the Initial state.

   function State_Of (M : Machine) return State;
   --  The machine's current state.

   procedure Fire (M : in out Machine; On : Event)
   with Post => State_Of (M) = Next (State_Of (M)'Old, On);
   --  Advance the machine to Next (current state, On).

private

   type Machine is record
      Current : State := Initial;
   end record;

   function State_Of (M : Machine) return State
   is (M.Current);

end Sml_Ada.State_Machines;
