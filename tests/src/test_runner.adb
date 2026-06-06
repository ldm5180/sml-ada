with Ada.Command_Line;

with AUnit;
use type AUnit.Status;
with AUnit.Reporter.Text;
with AUnit.Run;

with Sml_Ada_Suite;

procedure Test_Runner is

   function Run is new AUnit.Run.Test_Runner_With_Status (Sml_Ada_Suite.Suite);

   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Outcome  : AUnit.Status;

begin
   Outcome := Run (Reporter);
   Ada.Command_Line.Set_Exit_Status
     (if Outcome = AUnit.Success
      then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end Test_Runner;
