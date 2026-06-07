--  Drives the GENERATED machine.  Same driving code as example/hello_world.adb,
--  but Make/State_Of/Process_Event come from the generated Hello_World_Compiled,
--  whose Process_Event is a jump-table `case` on the current state (O(1)) that
--  GNAT dissolves to branches at -O2/-O3 -- no transition table, no scan.

with Ada.Text_IO; use Ada.Text_IO;

with Hello_World_Def;      use Hello_World_Def;
with Hello_World_Compiled; use Hello_World_Compiled;

procedure Run is
   M   : Machine := Make (Initial);
   Ctx : Context := (null record);
begin
   Put_Line ("start: " & State_Of (M)'Image);
   Process_Event (M, Ctx, (Kind => E_Release));
   Process_Event (M, Ctx, (Kind => E_Ack, Ack_Valid => True));
   Process_Event (M, Ctx, (Kind => E_Fin, Id => 42, Fin_Valid => True));
   Process_Event (M, Ctx, (Kind => E_Timeout));
   Put_Line ("final: " & State_Of (M)'Image);
end Run;
