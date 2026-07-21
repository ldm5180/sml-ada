--  A concrete Sml.Effects_Loop instance so gnatprove verifies the driver:
--  the loop and its step counter are proved free of run-time errors (the
--  bounded-mode increment in particular can never overflow), with actuals
--  over real package state -- the composed shape a runner actually wires.

package Effects_Loop_Proof
  with SPARK_Mode
is

   type Command is (None, Do_Work);

   procedure Run;

end Effects_Loop_Proof;
