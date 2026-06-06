--  Exercises the GENERATED Tcp_Compiled machine.  CI builds and runs this to
--  prove the generated code compiles and behaves, then regenerates and diffs
--  to catch drift between the table and the generated sources.

with Ada.Text_IO; use Ada.Text_IO;

with Tcp_Defs;     use Tcp_Defs;
with Tcp_Compiled; use Tcp_Compiled;

procedure Check is
   M   : Machine := Make (Established);
   Ctx : Context := (null record);
begin
   Put_Line ("start: " & State_Of (M)'Image);
   Process_Event (M, Ctx, (Kind => Release));
   Process_Event (M, Ctx, (Kind => Ack, Ack_Valid => True));
   Process_Event (M, Ctx, (Kind => Fin, Id => 42, Fin_Valid => True));
   Process_Event (M, Ctx, (Kind => Timeout));
   Put_Line ("final: " & State_Of (M)'Image);
end Check;
