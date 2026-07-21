with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with AUnit.Assertions; use AUnit.Assertions;

with Sml.Trace_Gate;

package body Sml_Trace_Gate_Tests is

   use AUnit.Test_Cases.Registration;

   type S is (S1, S2);
   type E is (E1, E2);
   type G is (Always);
   type A is (Nothing, Act);

   Captured : Unbounded_String;
   Gate_On  : Boolean := True;

   procedure Cap (Line : String) is
   begin
      Append (Captured, Line & ";");
   end Cap;

   function On return Boolean
   is (Gate_On);

   package Gate is new
     Sml.Trace_Gate
       (State       => S,
        Event_Kind  => E,
        Guard_Kind  => G,
        Action_Kind => A,
        Name        => "TEST",
        Always      => Always,
        Nothing     => Nothing,
        Put_Line    => Cap,
        Enabled     => On);

   --  The gate forwards each hook to Sml.Tracing only when Enabled, so
   --  a quiet (non-verbose) run formats nothing -- the per-event waste
   --  a hot-path runner would otherwise guard by hand.  This is that
   --  guard, once.
   procedure Test_Gates (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Captured := Null_Unbounded_String;

      Gate_On := False;
      Gate.On_Event (E1, S1);
      Gate.On_Guard (Always, True);
      Gate.On_Action (Act, S1, S2);
      Gate.On_Unhandled (E2, S2);
      Assert
        (Length (Captured) = 0, "disabled: no hook formats or emits a line");

      --  A traced line is composed across On_Event (start) and On_Action
      --  (endpoints, which flush it), so drive a full transition.
      Gate_On := True;
      Gate.On_Event (E1, S1);
      Gate.On_Action (Act, S1, S2);
      Assert
        (Index (Captured, "TEST") > 0,
         "enabled: the traced line is forwarded to Put_Line");
   end Test_Gates;

   overriding
   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T, Test_Gates'Access, "hooks forward only when Enabled");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String
   is (AUnit.Format ("Sml.Trace_Gate (level-gated sml tracing)"));

end Sml_Trace_Gate_Tests;
