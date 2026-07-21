--  A concrete Sml.Trace_Gate instance so gnatprove verifies the gate:
--  the four gated hooks (and the Sml.Tracing instance inside them) are
--  proved free of run-time errors with a stateful sink and a stateful
--  Enabled -- the composed shape a gated runner actually wires.

with Sml.Trace_Gate;

package Trace_Gate_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event_Kind is (E_Coin, E_Push);
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing, Act);

   --  The sink counts lines (saturating) rather than printing, as in
   --  Tracing_Proof.
   Lines : Natural := 0;

   procedure Count (Item : String);

   Gate_On : Boolean := True;

   function On return Boolean
   is (Gate_On);

   package Gate is new
     Sml.Trace_Gate
       (State       => State,
        Event_Kind  => Event_Kind,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Name        => "PROOF",
        Always      => Always,
        Nothing     => Nothing,
        Put_Line    => Count,
        Enabled     => On);

   procedure Run;

end Trace_Gate_Proof;
